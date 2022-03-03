import "dart:io";
import "dart:convert";

import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/service/database.dart";

import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as path;
import "package:get_it/get_it.dart";

class AvatarService {
  final Logger _log;
  final void Function(BaseIsolateEvent) sendData;
  
  AvatarService(this.sendData) : _log = Logger("AvatarService");

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
      
      sendData(ConversationUpdatedEvent(conversation: conv));
    } else {
      _log.warning("Failed to get conversation");
    }

    final originalRoster = await db.getRosterItemByJid(jid);
    if (originalRoster != null) {
      final roster = await db.updateRosterItem(
        id: originalRoster.id,
        avatarUrl: path
      );

      sendData(RosterDiffEvent(changedItems: [roster]));
    }
  }
}
