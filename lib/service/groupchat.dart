import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/groupchat.dart';
import 'package:moxxyv2/shared/models/groupchat_member.dart';

/// The value of the "var" attribute of the field containing the avatar hash (for Prosody).
const _prosodyAvatarHashFieldVar =
    '{http://modules.prosody.im/mod_vcard_muc}avatar#sha1';

class GroupchatService {
  /// Logger.
  final Logger _log = Logger('GroupchatService');

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
      final result = await mm.joinRoom(
        muc,
        nick,
        maxHistoryStanzas: 0,
      );
      if (result.isType<MUCError>()) {
        return Result(
          GroupchatErrorType.fromException(
            result.get<MUCError>(),
          ),
        );
      } else {
        // TODO(Unknown): Maybe be a bit smarter about it
        final db = GetIt.I.get<DatabaseService>().database;
        await db.delete(
          groupchatMembersTable,
          where: 'roomJid = ? AND accountJid = ?',
          whereArgs: [muc.toString(), accountJid],
        );
        final state = (await mm.getRoomState(muc))!;
        final members = List<GroupchatMember>.empty(growable: true);
        _log.finest('Got ${state.members.length} members for $muc');
        for (final rawMember in state.members.values) {
          final member = GroupchatMember(
            accountJid,
            muc.toString(),
            rawMember.nick,
            rawMember.role,
            rawMember.affiliation,
            null,
            null,
            null,
            false,
          );
          await db.insert(
            groupchatMembersTable,
            member.toJson(),
          );
          members.add(member);
        }
        // Add the self-participant
        await db.insert(
          groupchatMembersTable,
          GroupchatMember(
            accountJid,
            muc.toString(),
            state.nick!,
            state.role!,
            state.affiliation!,
            null,
            null,
            null,
            true,
          ).toJson(),
        );

        // TODO(Unknown): In case the MUC changed our nick, update the groupchat details to reflect this.

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
    if (accountJid == null) {
      return [];
    }

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

  /// Requests the latest SHA-1 hash of the avatar of the groupchat at [jid].
  Future<String?> getGroupchatAvatarHash(JID jid) async {
    final infoResult = await getRoomInformation(jid);
    if (infoResult.isType<MUCError>()) {
      return null;
    }
    final info = infoResult.get<RoomInformation>();

    // Check if an avatar is advertised.
    final hashField = info.roomInfo?.getFieldByVar(_prosodyAvatarHashFieldVar);
    if (hashField == null || hashField.values.isEmpty) {
      return null;
    }
    return hashField.values.first;
  }

  Future<List<GroupchatMember>> getMembers(JID muc, String accountJid) async {
    final result = await GetIt.I.get<DatabaseService>().database.query(
      groupchatMembersTable,
      where: 'roomJid = ? AND accountJid = ?',
      whereArgs: [muc.toString(), accountJid],
    );
    return result.map(GroupchatMember.fromJson).toList();
  }

  /// Deal with a member joining the groupchat [muc].
  Future<void> handleGroupchatMemberLeaving(
    JID muc,
    String accountJid,
    String nick,
  ) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final memberRaw = await db.query(
      groupchatMembersTable,
      where: 'roomJid = ? AND nick = ? AND accountJid = ?',
      whereArgs: [muc.toString(), nick, accountJid],
    );
    if (memberRaw.isEmpty) {
      _log.warning('Could not find groupchat member $muc/$nick');
      return;
    }
    final member = GroupchatMember.fromJson(memberRaw.first);

    // Delete the member's data.
    await db.delete(
      groupchatMembersTable,
      where: 'roomJid = ? AND nick = ? AND accountJid = ?',
      whereArgs: [muc.toString(), nick, accountJid],
    );

    // Maybe remove the avatar data.
    if (member.avatarPath != null) {
      await GetIt.I.get<AvatarService>().safeRemoveAvatar(
            member.avatarPath,
            false,
          );
    }
  }

  /// Deal with a member leaving the groupchat [muc].
  Future<void> handleGroupchatMemberJoining(
    JID muc,
    String accountJid,
    String nick,
    Affiliation affiliation,
    Role role,
  ) async {
    final member = GroupchatMember(
      accountJid,
      muc.toString(),
      nick,
      role,
      affiliation,
      null,
      null,
      null,
      false,
    );
    await GetIt.I.get<DatabaseService>().database.insert(
          groupchatMembersTable,
          member.toJson(),
        );
  }

  /// Deal with a member changing their nickname inside [muc].
  Future<void> handleGroupchatNicknameChange(
    JID muc,
    String accountJid,
    String oldNick,
    String newNick,
  ) async {
    final db = GetIt.I.get<DatabaseService>().database;
    await db.update(
      groupchatMembersTable,
      {
        'nick': newNick,
      },
      where: 'roomJid = ? AND accountJid = ? AND nick = ?',
      whereArgs: [muc.toString(), accountJid, oldNick],
    );
  }
}
