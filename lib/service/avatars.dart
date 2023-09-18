import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/cache.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:path/path.dart' as p;

class AvatarService {
  final Logger _log = Logger('AvatarService');

  /// List of JIDs for which we have already requested the avatar in the current stream.
  final List<JID> _requestedInStream = [];

  /// Cached version of the path to the avatar cache. Used to prevent constant calls
  /// to the native side.
  late final String _avatarCacheDir;

  /// Computes the path to use for cached avatars.
  static Future<String> getCachePath() async =>
      computeCacheDirectoryPath('avatars');

  @visibleForTesting
  void initializeForTesting(String cacheDir) {
    _avatarCacheDir = cacheDir;
  }

  Future<void> initialize() async {
    _avatarCacheDir = await getCachePath();
  }

  void resetCache() {
    _requestedInStream.clear();
  }

  String _computeAvatarPath(String hash) =>
      p.join(_avatarCacheDir, '$hash.png');

  /// Returns whether we can remove the avatar file at [path] by checking if the
  /// avatar is referenced by any other conversation. If [ignoreSelf] is true, then
  /// our own avatar is also taken into consideration.
  @visibleForTesting
  Future<bool> canRemoveAvatar(String path, bool ignoreSelf) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as usage FROM $conversationsTable WHERE avatarPath = ?',
      [path],
    );

    final ownModifier =
        (await GetIt.I.get<XmppStateService>().state).avatarUrl == path &&
                !ignoreSelf
            ? 1
            : 0;
    return (result.first['usage']! as int) + ownModifier == 0;
  }

  /// Remove the avatar file at [path], if [path] is non-null and [canRemoveAvatar] approves.
  /// [ignoreSelf] is passed to [canRemoveAvatar]'s ignoreSelf parameter.
  Future<void> _safeRemove(String? path, bool ignoreSelf) async {
    if (path == null) {
      return;
    }

    if (await canRemoveAvatar(path, ignoreSelf) && File(path).existsSync()) {
      await File(path).delete();
    }
  }

  /// Checks if the avatar with the specified hash already exists on disk.
  bool _hasAvatar(String hash) => File(_computeAvatarPath(hash)).existsSync();

  /// Save the avatar, described by the raw bytes [bytes] and its hash [hash], into
  /// the avatar cache directory.
  Future<void> _saveAvatarInCache(List<int> bytes, String hash) async {
    final dir = Directory(_avatarCacheDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // Write the avatar
    await File(_computeAvatarPath(hash)).writeAsBytes(bytes);
  }

  /// Fetches the avatar with id [id] for [jid], if we don't already have it locally.
  Future<String?> _maybeFetchAvatarForJid(
    JID jid,
    String id,
  ) async {
    if (_hasAvatar(id)) {
      return _computeAvatarPath(id);
    }

    // Check if we even have to request it.
    if (_hasAvatar(id)) {
      return _computeAvatarPath(id);
    }

    // Request the avatar data and write it to disk.
    final rawAvatar = await GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!
        .getUserAvatarData(jid, id);
    if (rawAvatar.isType<AvatarError>()) {
      _log.warning('Failed to request avatar ($jid, $id)');
      return null;
    }

    // Verify the hash
    final data = rawAvatar.get<UserAvatarData>().data;
    final hexHash = rawAvatar.get<UserAvatarData>().hash;
    final actualHexHash = HEX.encode(
      (await Sha1().hash(data)).bytes,
    );
    if (actualHexHash != hexHash) {
      _log.warning(
        'Avatar hash of $jid ($hexHash) is not equal to the computed hash ($actualHexHash)',
      );
      return null;
    }

    await _saveAvatarInCache(
      data,
      hexHash,
    );
    return _computeAvatarPath(id);
  }

  Future<void> _applyNewAvatarToJid(JID jid, String hash) async {
    assert(_hasAvatar(hash), 'The avatar must exist');

    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final accountJid = (await GetIt.I.get<XmppStateService>().getAccountJid())!;
    final conversation =
        await cs.getConversationByJid(jid.toString(), accountJid);
    final rosterItem = await rs.getRosterItemByJid(jid.toString(), accountJid);

    // Do nothing if we do not know of the JID.
    if (conversation == null && rosterItem == null) {
      return;
    }

    // Update the conversation
    final avatarPath = _computeAvatarPath(hash);
    if (conversation != null) {
      final newConversation = await cs.createOrUpdateConversation(
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
      sendEvent(
        ConversationUpdatedEvent(conversation: newConversation!),
      );

      // Try to delete the old avatar
      await _safeRemove(conversation.avatarPath, false);
    }

    // Update the roster item
    if (rosterItem != null) {
      final newRosterItem = await rs.updateRosterItem(
        jid.toString(),
        accountJid,
        avatarPath: avatarPath,
        avatarHash: hash,
      );
      sendEvent(
        RosterDiffEvent(modified: [newRosterItem]),
      );

      // Try to delete the old avatar
      await _safeRemove(rosterItem.avatarPath, false);
    }

    // Update the UI.
    sendEvent(
      AvatarUpdatedEvent(jid: jid.toString(), path: avatarPath),
    );
  }

  Future<void> handleAvatarUpdate(UserAvatarUpdatedEvent event) async {
    if (event.metadata.isEmpty) {
      return;
    }

    // Add the JID to the pending requests list.
    _requestedInStream.add(event.jid);

    // Fetch the new avatar.
    final metadata = event.metadata
        .firstWhereOrNull((element) => element.type == 'image/png');
    if (metadata == null) {
      _log.warning(
        'Avatar metadata from ${event.jid} does not advertise an image/png avatar, which violates XEP-0084',
      );
      return;
    }
    final newAvatarPath = await _maybeFetchAvatarForJid(
      event.jid,
      metadata.id,
    );
    if (newAvatarPath == null) {
      _log.warning('Failed to fetch avatar ${metadata.id} for ${event.jid}');
      _requestedInStream.remove(event.jid);
      return;
    }

    // Update the conversation.
    await _applyNewAvatarToJid(event.jid, metadata.id);

    // Remove the JID from the pending requests list.
    _requestedInStream.remove(event.jid);
  }

  /// Request the avatar for [jid], given its optional previous avatar hash [oldHash].
  Future<String?> requestAvatar(JID jid, String? oldHash) async {
    // Prevent multiple requests in a row.
    if (_requestedInStream.contains(jid)) {
      return null;
    }
    _requestedInStream.add(jid);

    // Request the latest metadata.
    final rawMetadata = await GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!
        .getLatestMetadata(jid);
    if (rawMetadata.isType<AvatarError>()) {
      _log.warning('Failed to get metadata for $jid');
      _requestedInStream.remove(jid);
      return null;
    }

    // Find the first metadata item that advertises a PNG avatar.
    final id = rawMetadata
        .get<List<UserAvatarMetadata>>()
        .firstWhereOrNull((element) => element.type == 'image/png')
        ?.id;
    if (id == null) {
      _log.warning(
        '$jid does not advertise an avatar of type image/png, which violates XEP-0084',
      );
      return null;
    }

    // Check if the id changed.
    if (id == oldHash) {
      _log.finest(
        'Remote id ($id) is equal to local id ($oldHash) for $jid. Not fetching avatar.',
      );
      _requestedInStream.remove(jid);
      return _computeAvatarPath(id);
    }

    // Request the new avatar.
    final newAvatarPath = await _maybeFetchAvatarForJid(
      jid,
      id,
    );
    if (newAvatarPath == null) {
      _log.warning('Failed to request avatar for $jid');
      _requestedInStream.remove(jid);
      return null;
    }

    // Update conversations.
    await _applyNewAvatarToJid(jid, id);

    // Remove the JID from the pending requests list.
    _requestedInStream.remove(jid);
    return _computeAvatarPath(id);
  }

  /// Request the avatar for our own avatar.
  Future<bool> requestOwnAvatar() async {
    final xss = GetIt.I.get<XmppStateService>();
    final jid = JID.fromString((await xss.getAccountJid())!);

    // Prevent multiple requests in a row.
    if (_requestedInStream.contains(jid)) {
      return true;
    }
    _requestedInStream.add(jid);

    // Get the current id.
    final state = await xss.state;
    final rawMetadata = await GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!
        .getLatestMetadata(jid);

    // Find the first metadata item that advertises a PNG avatar.
    final id = rawMetadata
        .get<List<UserAvatarMetadata>>()
        .firstWhereOrNull((element) => element.type == 'image/png')
        ?.id;
    if (id == null) {
      _log.warning(
        'We ($jid) do not advertise an avatar of type image/png, which violates XEP-0084',
      );
      return false;
    }

    // Check if the avatar even changed.
    if (id == state.avatarHash) {
      _log.finest(
        'Not requesting our own avatar because the server-side id ($id) is equal to our current id (${state.avatarHash})',
      );
      _requestedInStream.remove(jid);
      return true;
    }

    // Request the new avatar.
    final oldAvatarPath = state.avatarUrl;
    final newAvatarPath = await _maybeFetchAvatarForJid(
      jid,
      id,
    );
    if (newAvatarPath == null) {
      _log.warning('Failed to request own avatar');
      _requestedInStream.remove(jid);
      return false;
    }

    // Update the state and the UI.
    await xss.modifyXmppState(
      (s) {
        return s.copyWith(
          avatarUrl: newAvatarPath,
          avatarHash: id,
        );
      },
    );
    sendEvent(SelfAvatarChangedEvent(path: newAvatarPath, hash: id));

    // Try to safely delete the old avatar.
    await _safeRemove(oldAvatarPath, true);

    // Update the notification UI.
    await GetIt.I.get<NotificationsService>().maybeSetAvatarFromState();

    // Remove our JID from the pending requests list.
    _requestedInStream.remove(jid);
    return true;
  }

  Future<bool> setNewAvatar(String path, String hash) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final isPublic = (await GetIt.I.get<PreferencesService>().getPreferences())
        .isAvatarPublic;

    // Copy the avatar into the cache, if we don't already have it.
    final avatarPath = _computeAvatarPath(hash);
    if (!_hasAvatar(hash)) {
      await file.copy(avatarPath);
    }

    // Get image metadata.
    final imageSize = (await getImageSizeFromPath(avatarPath))!;

    // Publish data and metadata
    final am = GetIt.I
        .get<XmppConnection>()
        .getManagerById<UserAvatarManager>(userAvatarManager)!;
    _log.finest('Publishing avatar');
    final dataResult = await am.publishUserAvatar(base64, hash, isPublic);
    if (dataResult.isType<AvatarError>()) {
      _log.warning('Failed to publish avatar data');
      return false;
    }

    // Publish the metadata.
    final metadataResult = await am.publishUserAvatarMetadata(
      UserAvatarMetadata(
        hash,
        bytes.length,
        imageSize.width.toInt(),
        imageSize.height.toInt(),
        // TODO(Unknown): Make sure
        'image/png',
        null,
      ),
      isPublic,
    );
    if (metadataResult.isType<AvatarError>()) {
      _log.warning('Failed to publish avatar metadata');
      return false;
    }

    // Update the state
    final xss = GetIt.I.get<XmppStateService>();
    final state = await xss.state;
    final oldAvatarPath = state.avatarUrl;
    await xss.modifyXmppState(
      (s) {
        return s.copyWith(
          avatarUrl: avatarPath,
          avatarHash: hash,
        );
      },
    );

    // Update the UI
    sendEvent(SelfAvatarChangedEvent(path: avatarPath, hash: hash));

    // Update the notifications.
    await GetIt.I.get<NotificationsService>().maybeSetAvatarFromState();

    // Safely remove the old avatar
    await _safeRemove(oldAvatarPath, true);

    // Remove the temp file.
    await file.delete();
    return true;
  }
}
