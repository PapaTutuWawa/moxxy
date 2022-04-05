import "dart:io";
import "dart:convert";

import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";
import "package:moxxyv2/xmpp/xeps/xep_0054.dart";
import "package:moxxyv2/xmpp/xeps/xep_0084.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as path;
import "package:get_it/get_it.dart";
import "package:hex/hex.dart";
import "package:cryptography/cryptography.dart";

class AvatarService {
  final Logger _log;
  
  AvatarService() : _log = Logger("AvatarService");

  UserAvatarManager _getUserAvatarManager() => GetIt.I.get<XmppConnection>().getManagerById(userAvatarManager)! as UserAvatarManager;

  DiscoManager _getDiscoManager() => GetIt.I.get<XmppConnection>().getManagerById(discoManager)! as DiscoManager;
  
  Future<String> _getAvatarCacheDir() async {
    return path.join((await getTemporaryDirectory()).path, "avatar");
  }
  
  Future<String> saveAvatar(String jid, String hash, String base64) async {
    final cachePath = await _getAvatarCacheDir();
    final f = File(path.join(cachePath, jid + "_" + hash));
    if (!(await f.exists())) await f.create(recursive: true);

    await f.writeAsBytes(base64Decode(base64));

    return f.path;
  }

  Future<void> updateAvatarForJid(String jid, String hash, String base64) async {
    final path = await GetIt.I.get<AvatarService>().saveAvatar(
      jid,
      hash,
      base64
    );

    final db = GetIt.I.get<DatabaseService>();
    final originalConversation = await db.getConversationByJid(jid);
    if (originalConversation != null) {
      final conv = await db.updateConversation(
        id: originalConversation.id,
        avatarUrl: path
      );

      // Remove the old avatar$
      final oldAvatar = File(originalConversation.avatarUrl);
      if (await oldAvatar.exists()) await oldAvatar.delete();

      sendEvent(ConversationUpdatedEvent(conversation: conv));
    } else {
      _log.warning("Failed to get conversation");
    }

    final originalRoster = await db.getRosterItemByJid(jid);
    if (originalRoster != null) {
      final roster = await db.updateRosterItem(
        id: originalRoster.id,
        avatarUrl: path
      );

      sendEvent(RosterDiffEvent(modified: [roster]));
    }
  }

  Future<void> fetchAndUpdateAvatarForJid(String jid) async {
    final items = (await _getDiscoManager().discoItemsQuery(jid)) ?? [];

    String base64 = "";
    String hash = "";
    if (listContains<DiscoItem>(items, (item) => item.node == userAvatarDataXmlns)) {
      // Query via PubSub
      final data = await _getUserAvatarManager().getUserAvatar(jid);
      if (data == null) return;
      
      base64 = data.base64;
      hash = data.hash;
    } else {
      // Query the vCard
      final vm = GetIt.I.get<XmppConnection>().getManagerById(vcardManager)! as vCardManager;
      final vcard = await vm.requestVCard(jid.toString());
      if (vcard != null) {
        final binval = vcard.photo?.binval;
        if (binval != null) {
          base64 = binval;
          final rawHash = await Sha1().hash(base64Decode(binval));
          hash = HEX.encode(rawHash.bytes);

          vm.setLastHash(jid.toString(), hash);
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
    return await _getUserAvatarManager().subscribe(jid);
  }

  Future<bool> unsubscribeJid(String jid) async {
    return await _getUserAvatarManager().unsubscribe(jid);
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

    return await _getUserAvatarManager().publishUserAvatar(
      base64,
      hash,
      public
    );
  }
}
