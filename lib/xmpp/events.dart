import "package:moxxyv2/xmpp/jid.dart";

abstract class XmppEvent {}

class MessageEvent extends XmppEvent {
  final String body;
  final FullJID fromJid;
  final String sid;

  MessageEvent({ required this.body, required this.fromJid, required this.sid });
}

enum ChatMarkerType {
  MARKABLE, RECEIVED, DISPLAYED, ACKNOWLEDGED, UNKNOWN
}

ChatMarkerType chatMarkerFromTag(String tag) {
  switch (tag) {
    case "markable": return ChatMarkerType.MARKABLE;
    case "received": return ChatMarkerType.RECEIVED;
    case "displayed": return ChatMarkerType.DISPLAYED;
    case "acknowledged": return ChatMarkerType.ACKNOWLEDGED;
  }

  return ChatMarkerType.UNKNOWN;
}

class ChatMarkerEvent extends XmppEvent {
  final ChatMarkerType type;
  final String sid;

  ChatMarkerEvent({ required this.type, required this.sid });
}

// Triggered when we received a Stream resumption ID
// TODO: Make the id optional since a server doesn't have to support resumption
class StreamManagementEnabledEvent extends XmppEvent {
  final String resource;
  final String id;

  StreamManagementEnabledEvent({ required this.id, required this.resource });
}

// Triggered when we send out an ack
class StreamManagementAckSentEvent extends XmppEvent {
  final int h;

  StreamManagementAckSentEvent({ required this.h });
}

// Triggered when we were able to successfully resume a stream
class StreamManagementResumptionSuccessfulEvent extends XmppEvent {}
