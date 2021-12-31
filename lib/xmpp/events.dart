abstract class XmppEvent {}

class MessageEvent extends XmppEvent {
  final String body;
  final String fromJid;
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
class StreamResumptionEvent extends XmppEvent {
  final String resource;
  final String id;

  StreamResumptionEvent({ required this.id, required this.resource });
}
