import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/shared/error_types.dart';

class GroupchatService {
  Future<bool> isRoomPasswordProtected(JID roomJID) async {
    final roomInformation = await getRoomInformation(roomJID);
    return roomInformation.features.contains('muc_passwordprotected');
  }

  Future<RoomInformation> getRoomInformation(JID roomJID) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final result = await mm.queryRoomInformation(roomJID);
    if (result is RoomInformation) {
      return result.get<RoomInformation>();
    }
    throw Exception(result.get<MUCError>());
  }

  Future<bool> joinRoom(JID muc, String nick) async {
    final conn = GetIt.I.get<XmppConnection>();
    final mm = conn.getManagerById<MUCManager>(mucManager)!;
    final roomPasswordProtected = await isRoomPasswordProtected(muc);
    if (roomPasswordProtected) {
      throw Exception(GroupchatErrorType.roomPasswordProtected);
    }
    final result = await mm.joinRoom(muc, nick);
    if (result is MUCError) {
      throw Exception(GroupchatErrorType.fromException(result.get<MUCError>()));
    } else {
      return result.get<bool>();
    }
  }
}
