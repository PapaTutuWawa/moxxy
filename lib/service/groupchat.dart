import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/groupchat.dart';

class GroupchatService {
  Future<RoomInformation> getRoomInformation(JID roomJID) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final result = await mm.queryRoomInformation(roomJID);
    if (result.isType<RoomInformation>()) {
      return result.get<RoomInformation>();
    }
    throw Exception(result.get<MUCError>());
  }

  Future<GroupchatDetails> joinRoom(JID muc, String nick) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final roomInformation = await getRoomInformation(muc);
    final roomPasswordProtected =
        roomInformation.features.contains('muc_passwordprotected');
    if (roomPasswordProtected) {
      throw Exception(GroupchatErrorType.roomPasswordProtected);
    }
    final result = await mm.joinRoom(muc, nick);
    if (result.isType<MUCError>()) {
      throw Exception(GroupchatErrorType.fromException(result.get<MUCError>()));
    } else {
      return GroupchatDetails(
        muc.toBare().toString(),
        nick,
        roomInformation.name,
      );
    }
  }

  Future<GroupchatDetails> addGroupchatDetailsFromData(
    String jid,
    String nick,
    String title,
  ) async {
    final groupchatDetails = GroupchatDetails(jid, nick, title);
    await GetIt.I.get<DatabaseService>().database.insert(
          groupchatTable,
          groupchatDetails.toJson(),
        );

    return groupchatDetails;
  }

  Future<GroupchatDetails?> getGroupchatDetailsByJid(String jid) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final groupchatDetailsRaw = await db.query(
      groupchatTable,
      where: 'jid = ?',
      whereArgs: [jid],
    );
    if (groupchatDetailsRaw.isEmpty) return null;
    return GroupchatDetails.fromDatabaseJson(groupchatDetailsRaw[0]);
  }
}
