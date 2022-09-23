import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/avatar.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/errors.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0054.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0084.dart';

/// Removes line breaks and spaces from [original]. This might happen when we request the
/// avatar data. Returns the cleaned version.
String _cleanBase64String(String original) {
  var ret = original;
  for (final char in ['\n', ' ']) {
    ret = ret.replaceAll(char, '');
  }

  return ret;
}

class AvatarService {
  
  AvatarService() : _log = Logger('AvatarService');
  final Logger _log;

  UserAvatarManager _getUserAvatarManager() => GetIt.I.get<XmppConnection>().getManagerById<UserAvatarManager>(userAvatarManager)!;

  DiscoManager _getDiscoManager() => GetIt.I.get<XmppConnection>().getManagerById<DiscoManager>(discoManager)!;
  
  Future<void> updateAvatarForJid(String jid, String hash, String base64) async {
    final cs = GetIt.I.get<ConversationService>();
    final rs = GetIt.I.get<RosterService>();
    final originalConversation = await cs.getConversationByJid(jid);
    var saved = false;

    // Clean the raw data. Since this may arrive by chunks, those chunks may contain
    // weird data pieces.
    final base64Data = base64Decode(_cleanBase64String(base64));
    if (originalConversation != null) {
      final avatarPath = await saveAvatarInCache(
        base64Data,
        hash,
        jid,
        originalConversation.avatarUrl,
      );
      saved = true;
      final conv = await cs.updateConversation(
        originalConversation.id,
        avatarUrl: avatarPath,
      );

      sendEvent(ConversationUpdatedEvent(conversation: conv));
    } else {
      _log.warning('Failed to get conversation');
    }

    final originalRoster = await rs.getRosterItemByJid(jid);
    if (originalRoster != null) {
      var avatarPath = '';
      if (saved) {
        avatarPath = await getAvatarPath(jid, hash);
      } else {
        avatarPath = await saveAvatarInCache(
          base64Data,
          hash,
          jid,
          originalRoster.avatarUrl,
        ); 
      }

      final roster = await rs.updateRosterItem(
        originalRoster.id,
        avatarUrl: avatarPath,
        avatarHash: hash,
      );

      sendEvent(RosterDiffEvent(modified: [roster]));
    }
  }
  
  Future<void> fetchAndUpdateAvatarForJid(String jid, String oldHash) async {
    final response = await _getDiscoManager().discoItemsQuery(jid);
    final items = response.isType<DiscoError>() ?
      <DiscoItem>[] :
      response.get<List<DiscoItem>>();
    final itemNodes = items.map((i) => i.node);

    _log.finest('Disco items for $jid:');
    for (final item in itemNodes) {
      _log.finest('- $item');
    }
    
    var base64 = '';
    var hash = '';
    if (listContains<DiscoItem>(items, (item) => item.node == userAvatarDataXmlns)) {
      final avatar = _getUserAvatarManager();
      final pubsubHash = await avatar.getAvatarId(jid);

      // Don't request if we already have the newest avatar
      if (pubsubHash == oldHash) return;
      
      // Query via PubSub
      final data = await avatar.getUserAvatar(jid);
      if (data == null) return;
      
      base64 = data.base64;
      hash = data.hash;
    } else {
      // Query the vCard
      final vm = GetIt.I.get<XmppConnection>().getManagerById<VCardManager>(vcardManager)!;
      final vcard = await vm.requestVCard(jid);
      if (vcard != null) {
        final binval = vcard.photo?.binval;
        if (binval != null) {
          // Clean the raw data. Since this may arrive by chunks, those chunks may contain
          // weird data pieces.
          base64 = _cleanBase64String(binval);

          final rawHash = await Sha1().hash(base64Decode(base64));
          hash = HEX.encode(rawHash.bytes);

          vm.setLastHash(jid, hash);
        } else {
          return;
        }
      } else {
        return;
      }
    }

    await updateAvatarForJid(jid, hash, base64);
  }
  
  Future<bool> subscribeJid(String jid) async {
    return _getUserAvatarManager().subscribe(jid);
  }

  Future<bool> unsubscribeJid(String jid) async {
    return _getUserAvatarManager().unsubscribe(jid);
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
    final imageSize = ImageSizeGetter.getSize(MemoryInput(bytes));
    
    // Publish data and metadata
    final manager = _getUserAvatarManager();
    await manager.publishUserAvatar(
      base64,
      hash,
      public,
    );
    await manager.publishUserAvatarMetadata(
      UserAvatarMetadata(
        hash,
        bytes.length,
        imageSize.width,
        imageSize.height,
        // TODO(PapaTutuWawa): Maybe do a check here
        'image/png',
      ),
      public,
    );
    
    return true;
  }

  Future<void> requestOwnAvatar() async {
    final avatar = _getUserAvatarManager();
    final xmpp = GetIt.I.get<XmppService>();
    final state = await xmpp.getXmppState();
    final jid = state.jid!;
    final id = await avatar.getAvatarId(jid);

    if (id == state.avatarHash) return;

    _log.info('Mismatch between saved avatar data and server-side avatar data about ourself');
    final data = await avatar.getUserAvatar(jid);
    if (data == null) {
      _log.severe('Failed to fetch our avatar');
      return;
    }

    _log.info('Received data for our own avatar');
    
    final avatarPath = await saveAvatarInCache(
      base64Decode(_cleanBase64String(data.base64)),
      data.hash,
      jid,
      state.avatarUrl,
    );
    await xmpp.modifyXmppState((state) => state.copyWith(
      avatarUrl: avatarPath,
      avatarHash: data.hash,
    ),);

    sendEvent(SelfAvatarChangedEvent(path: avatarPath, hash: data.hash));
  }
}
