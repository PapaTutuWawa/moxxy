import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/groupchat.dart';

class GroupchatService {
  /// Retrieves the information about a group chat room specified by the given
  /// JID.
  /// Returns a [Future] that resolves to a [RoomInformation] object containing
  /// details about the room.
  Future<RoomInformation> getRoomInformation(JID roomJID) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final result = await mm.queryRoomInformation(roomJID);
    if (result.isType<RoomInformation>()) {
      return result.get<RoomInformation>();
    }
    throw Exception(result.get<MUCError>());
  }

  /// Joins a group chat room specified by the given MUC JID and a nickname.
  /// Returns a [Future] that resolves to a [GroupchatDetails] object
  /// representing the details of the joined room.
  /// Throws an exception of type [GroupchatErrorType.roomPasswordProtected]
  /// if the room requires a password for entry.
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
      );
    }
  }

  /// Creates and adds group chat details to the database based on the provided
  /// JID, nickname, and title.
  /// Returns a [Future] that resolves to a [GroupchatDetails] object
  /// representing the added group chat details.
  Future<GroupchatDetails> addGroupchatDetailsFromData(
    String jid,
    String nick,
  ) async {
    final groupchatDetails = GroupchatDetails(jid, nick);
    await GetIt.I.get<DatabaseService>().database.insert(
          groupchatTable,
          groupchatDetails.toJson(),
        );

    return groupchatDetails;
  }

  /// Retrieves group chat details from the database based on the provided JID.
  ///
  /// Returns a [Future] that resolves to a [GroupchatDetails] object if found,
  /// or `null` if no matching details are found.
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
