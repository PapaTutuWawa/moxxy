import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/groupchat.dart';

class GroupchatService {
  /// Retrieves the information about a group chat room specified by the given
  /// JID.
  /// Returns a [Future] that resolves to a [RoomInformation] object containing
  /// details about the room.
  Future<Result<RoomInformation, MUCError>> getRoomInformation(
    JID roomJID,
  ) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final result = await mm.queryRoomInformation(roomJID);
    return result;
  }

  /// Joins a group chat room specified by the given MUC JID and a nickname.
  /// Returns a [Future] that resolves to a [GroupchatDetails] object
  /// representing the details of the joined room.
  /// Throws an exception of type [GroupchatErrorType.roomPasswordProtected]
  /// if the room requires a password for entry.
  Future<Result<GroupchatDetails, GroupchatErrorType>> joinRoom(
    JID muc,
    String accountJid,
    String nick,
  ) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final roomInformationResult = await getRoomInformation(muc);
    if (roomInformationResult.isType<RoomInformation>()) {
      final roomPasswordProtected = roomInformationResult
          .get<RoomInformation>()
          .features
          .contains('muc_passwordprotected');
      if (roomPasswordProtected) {
        return const Result(GroupchatErrorType.roomPasswordProtected);
      }
      final result = await mm.joinRoom(muc, nick);
      if (result.isType<MUCError>()) {
        return Result(
          GroupchatErrorType.fromException(
            result.get<MUCError>(),
          ),
        );
      } else {
        return Result(
          GroupchatDetails(
            muc.toBare().toString(),
            accountJid,
            nick,
          ),
        );
      }
    } else {
      return Result(
        GroupchatErrorType.fromException(
          roomInformationResult.get<MUCError>(),
        ),
      );
    }
  }

  /// Creates and adds group chat details to the database based on the provided
  /// JID, nickname, and title.
  /// Returns a [Future] that resolves to a [GroupchatDetails] object
  /// representing the added group chat details.
  Future<GroupchatDetails> addGroupchatDetailsFromData(
    String jid,
    String accountJid,
    String nick,
  ) async {
    final groupchatDetails = GroupchatDetails(jid, accountJid, nick);
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
  Future<GroupchatDetails?> getGroupchatDetailsByJid(
    String jid,
    String accountJid,
  ) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final groupchatDetailsRaw = await db.query(
      groupchatTable,
      where: 'jid = ? AND accountJid = ?',
      whereArgs: [jid, accountJid],
    );
    if (groupchatDetailsRaw.isEmpty) return null;
    return GroupchatDetails.fromDatabaseJson(groupchatDetailsRaw[0]);
  }

  /// Query the database for conversations that are open AND have attached groupchat
  /// details.
  Future<List<MUCRoomJoin>> getRoomsToJoin() async {
    final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
    final results = await GetIt.I.get<DatabaseService>().database.rawQuery('''
      SELECT
        c.jid as roomJid,
        d.nick as nick
      FROM
        $conversationsTable as c,
        $groupchatTable as d
      WHERE
        c.jid = d.jid AND
        c.open = ? AND
        c.accountJid = ? AND
        d.accountJid = ?
      ''', [
      boolToInt(true),
      accountJid,
      accountJid,
    ]);

    return results.map((result) {
      return (
        JID.fromString(result['roomJid']! as String),
        result['nick']! as String,
      );
    }).toList();
  }
}
