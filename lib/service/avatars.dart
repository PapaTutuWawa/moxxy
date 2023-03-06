import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/avatar.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';

/// Removes line breaks and spaces from [original]. This might happen when we request the
/// avatar data. Returns the cleaned version.
String _cleanBase64String(String original) {
  var ret = original;
  for (final char in ['\n', ' ']) {
    ret = ret.replaceAll(char, '');
  }

  return ret;
}

class _AvatarData {
  const _AvatarData(this.data, this.id);
  final List<int> data;
  final String id;
}

class AvatarService {
  final Logger _log = Logger('AvatarService');

  Future<void> handleAvatarUpdate(AvatarUpdatedEvent event) async {
    await updateAvatarForJid(
      event.jid,
      event.hash,
      base64Decode(_cleanBase64String(event.base64)),
    );
  }

  Future<void> updateAvatarForJid(
      String jid, String hash, List<int> data) async {
    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final originalConversation = await cs.getConversationByJid(jid);
    final originalRoster = await rs.getRosterItemByJid(jid);

    if (originalConversation == null && originalRoster == null) return;

    final avatarPath = await saveAvatarInCache(
      data,
      hash,
      jid,
      (originalConversation?.avatarUrl ?? originalRoster?.avatarUrl)!,
    );

    if (originalConversation != null) {
      final conversation = await cs.createOrUpdateConversation(
        jid,
        update: (c) async {
          return cs.updateConversation(
            jid,
            avatarUrl: avatarPath,
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
        originalRoster.id,
        avatarUrl: avatarPath,
        avatarHash: hash,
      );

      sendEvent(RosterDiffEvent(modified: [roster]));
    }
  }

  Future<_AvatarData?> _handleUserAvatar(String jid, String oldHash) async {
    final am = GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!;
    final idResult = await am.getAvatarId(jid);
    if (idResult.isType<AvatarError>()) {
      _log.warning('Failed to get avatar id via XEP-0084 for $jid');
      return null;
    }
    final id = idResult.get<String>();
    if (id == oldHash) return null;

    final avatarResult = await am.getUserAvatar(jid);
    if (avatarResult.isType<AvatarError>()) {
      _log.warning('Failed to get avatar data via XEP-0084 for $jid');
      return null;
    }
    final avatar = avatarResult.get<UserAvatar>();

    return _AvatarData(
      base64Decode(_cleanBase64String(avatar.base64)),
      avatar.hash,
    );
  }

  Future<_AvatarData?> _handleVcardAvatar(String jid, String oldHash) async {
    // Query the vCard
    final vm = GetIt.I
        .get<XmppConnection>()
        .getManagerById<VCardManager>(vcardManager)!;
    final vcardResult = await vm.requestVCard(jid);
    if (vcardResult.isType<VCardError>()) return null;

    final binval = vcardResult.get<VCard>().photo?.binval;
    if (binval == null) return null;

    final data = base64Decode(_cleanBase64String(binval));
    final rawHash = await Sha1().hash(data);
    final hash = HEX.encode(rawHash.bytes);

    vm.setLastHash(jid, hash);

    return _AvatarData(
      data,
      hash,
    );
  }

  Future<void> fetchAndUpdateAvatarForJid(String jid, String oldHash) async {
    _AvatarData? data;
    data ??= await _handleUserAvatar(jid, oldHash);
    data ??= await _handleVcardAvatar(jid, oldHash);

    if (data != null) {
      await updateAvatarForJid(jid, data.id, data.data);
    }
  }

  Future<bool> subscribeJid(String jid) async {
    return (await GetIt.I
            .get<XmppConnection>()
            .getManagerById<UserAvatarManager>(userAvatarManager)!
            .subscribe(jid))
        .isType<bool>();
  }

  Future<bool> unsubscribeJid(String jid) async {
    return (await GetIt.I
            .get<XmppConnection>()
            .getManagerById<UserAvatarManager>(userAvatarManager)!
            .unsubscribe(jid))
        .isType<bool>();
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

  Future<void> requestOwnAvatar() async {
    final am = GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!;
    final xss = GetIt.I.get<XmppStateService>();
    final state = await xss.getXmppState();
    final jid = state.jid!;
    final idResult = await am.getAvatarId(jid);
    if (idResult.isType<AvatarError>()) {
      _log.info('Error while getting latest avatar id for own avatar');
      return;
    }
    final id = idResult.get<String>();

    if (id == state.avatarHash) return;

    _log.info(
        'Mismatch between saved avatar data and server-side avatar data about ourself');
    final avatarDataResult = await am.getUserAvatar(jid);
    if (avatarDataResult.isType<AvatarError>()) {
      _log.severe('Failed to fetch our avatar');
      return;
    }
    final avatarData = avatarDataResult.get<UserAvatar>();

    _log.info('Received data for our own avatar');

    final avatarPath = await saveAvatarInCache(
      base64Decode(_cleanBase64String(avatarData.base64)),
      avatarData.hash,
      jid,
      state.avatarUrl,
    );
    await xss.modifyXmppState(
      (state) => state.copyWith(
        avatarUrl: avatarPath,
        avatarHash: avatarData.hash,
      ),
    );

    sendEvent(SelfAvatarChangedEvent(path: avatarPath, hash: avatarData.hash));
  }
}
