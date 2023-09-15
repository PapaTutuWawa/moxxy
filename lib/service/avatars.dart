import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/avatar.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';

// TODO: Rewrite to allow building a base that can share code with the file service
class AvatarService {
  final Logger _log = Logger('AvatarService');

  /// List of JIDs for which we have already requested the avatar in the current stream.
  final List<JID> _requestedInStream = [];

  void resetCache() {
    _requestedInStream.clear();
  }

  Future<bool> _fetchAvatarForJid(JID jid, String hash) async {
    final conn = GetIt.I.get<XmppConnection>();
    final am = conn.getManagerById<UserAvatarManager>(userAvatarManager)!;
    final rawAvatar = await am.getUserAvatar(jid);
    if (rawAvatar.isType<AvatarError>()) {
      _log.warning('Failed to request avatar for $jid');
      return false;
    }

    final avatar = rawAvatar.get<UserAvatarData>();
    await _updateAvatarForJid(
      jid,
      avatar.hash,
      avatar.data,
    );
    return true;
  }

  /// Requests the avatar for [jid]. [oldHash], if given, is the last SHA-1 hash of the known avatar.
  /// If the avatar for [jid] has already been requested in this stream session, does nothing. Otherwise,
  /// requests the XEP-0084 metadata and queries the new avatar only if the queried SHA-1 != [oldHash].
  ///
  /// Returns true, if everything went okay. Returns false if an error occurred.
  Future<bool> requestAvatar(JID jid, String? oldHash) async {
    if (_requestedInStream.contains(jid)) {
      return true;
    }

    _requestedInStream.add(jid);
    final conn = GetIt.I.get<XmppConnection>();
    final am = conn.getManagerById<UserAvatarManager>(userAvatarManager)!;
    final rawId = await am.getAvatarId(jid);

    if (rawId.isType<AvatarError>()) {
      _log.finest(
        'Failed to get avatar metadata for $jid using XEP-0084: ${rawId.get<AvatarError>()}',
      );
      return false;
    }
    final id = rawId.get<String>();
    if (id == oldHash) {
      if (oldHash != null) {
        final (_, path) = await getAvatarPath(oldHash);
        if (!File(path).existsSync()) {
          _log.finest('Avatar hashes match for $jid but the avatar at $path does not exist. Fetching avatar...');
        } else {
         _log.finest('Hashes match for $jid and the file exists. Not fetching avatar...');
         return true;
        }
      } else {
        _log.finest('Not fetching avatar for $jid since the hashes are equal');
        return true;
      }
    }

    return _fetchAvatarForJid(jid, id);
  }

  Future<void> handleAvatarUpdate(UserAvatarUpdatedEvent event) async {
    if (event.metadata.isEmpty) return;

    // TODO(Unknown): Maybe make a better decision?
    await _fetchAvatarForJid(event.jid, event.metadata.first.id);
  }

  /// Updates the avatar path and hash for the conversation and/or roster item with jid [JID].
  /// [hash] is the new hash of the avatar. [data] is the raw avatar data.
  Future<void> _updateAvatarForJid(
    JID jid,
    String hash,
    List<int> data,
  ) async {
    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
    final originalConversation =
        await cs.getConversationByJid(jid.toString(), accountJid!);
    final originalRoster = await rs.getRosterItemByJid(
      jid.toString(),
      accountJid,
    );

    if (originalConversation == null && originalRoster == null) return;

    final avatarPath = await saveAvatarInCache(
      data,
      hash,
      jid.toString(),
      originalConversation?.avatarPath ?? originalRoster?.avatarPath,
    );

    if (originalConversation != null) {
      final conversation = await cs.createOrUpdateConversation(
        jid.toString(),
        accountJid,
        update: (c) async {
          return cs.updateConversation(
            jid.toString(),
            accountJid,
            avatarPath: avatarPath,
            avatarHash: hash,
          );
        },
      );
      if (conversation != null) {
        sendEvent(
          ConversationUpdatedEvent(conversation: conversation),
        );
      }
    }

    if (originalRoster != null) {
      final roster = await rs.updateRosterItem(
        originalRoster.jid,
        accountJid,
        avatarPath: avatarPath,
        avatarHash: hash,
      );

      sendEvent(RosterDiffEvent(modified: [roster]));
    }

    sendEvent(
      AvatarUpdatedEvent(
        jid: jid.toString(),
        path: avatarPath,
      ),
    );
  }

  /// Publishes the data at [path] as an avatar with PubSub ID
  /// [hash]. [hash] must be the hex-encoded version of the SHA-1 hash
  /// of the avatar data.
  Future<bool> publishAvatar(String path, String hash) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    final public = prefs.isAvatarPublic;

    // Read the image metadata
    final imageSize = (await getImageSizeFromData(bytes))!;

    // Publish data and metadata
    final am = GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!;

    _log.finest('Publishing avatar...');
    final dataResult = await am.publishUserAvatar(
      base64,
      hash,
      public,
    );
    if (dataResult.isType<AvatarError>()) {
      _log.finest('Avatar data publishing failed');
      return false;
    }

    // TODO(Unknown): Make sure that the image is not too large.
    final metadataResult = await am.publishUserAvatarMetadata(
      UserAvatarMetadata(
        hash,
        bytes.length,
        imageSize.width.toInt(),
        imageSize.height.toInt(),
        // TODO(PapaTutuWawa): Maybe do a check here
        'image/png',
        null,
      ),
      public,
    );
    if (metadataResult.isType<AvatarError>()) {
      _log.finest('Avatar metadata publishing failed');
      return false;
    }

    _log.finest('Avatar publishing done');
    return true;
  }

  /// Like [requestAvatar], but fetches and processes the avatar for our own account.
  Future<void> requestOwnAvatar() async {
    final xss = GetIt.I.get<XmppStateService>();
    final accountJid = await xss.getAccountJid();
    final state = await xss.state;
    final jid = JID.fromString(accountJid!);

    if (_requestedInStream.contains(jid)) {
      return;
    }
    _requestedInStream.add(jid);

    final am = GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!;
    final rawId = await am.getAvatarId(jid);
    if (rawId.isType<AvatarError>()) {
      _log.finest(
        'Failed to get avatar metadata for $jid using XEP-0084: ${rawId.get<AvatarError>()}',
      );
      return;
    }
    final id = rawId.get<String>();


    if (id == state.avatarHash) {
      if (state.avatarHash != null) {
        final (_, path) = await getAvatarPath(state.avatarHash!);
        if (!File(path).existsSync()) {
          _log.finest('Avatar hashes match for our own avatar but the file at $path does not exist. Fetching avatar...');
        } else {
         _log.finest('Hashes match for own avatar and the file exists. Not fetching avatar...');
         return;
        }
      } else {
        _log.finest('Not fetching own avatar since the hashes are equal');
        return;
      }
    }

    final rawAvatar = await am.getUserAvatar(jid);
    if (rawAvatar.isType<AvatarError>()) {
      _log.warning('Failed to request avatar for $jid');
      return;
    }
    final avatarData = rawAvatar.get<UserAvatarData>();
    final avatarPath = await saveAvatarInCache(
      avatarData.data,
      avatarData.hash,
      jid.toString(),
      state.avatarUrl,
    );
    await xss.modifyXmppState(
      (state) => state.copyWith(
        avatarUrl: avatarPath,
        avatarHash: avatarData.hash,
      ),
    );

    // Update our notification avatar
    await GetIt.I.get<NotificationsService>().maybeSetAvatarFromState();

    sendEvent(SelfAvatarChangedEvent(path: avatarPath, hash: avatarData.hash));
  }
}
