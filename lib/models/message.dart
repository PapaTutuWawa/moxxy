import "package:equatable/equatable.dart";

class Message extends Equatable {
  final String body;
  final int timestamp; // NOTE: Milliseconds since Epoch
  final String from;
  final String conversationJid;
  final bool sent;
  final int id; // Database ID

  const Message({ required this.from, required this.body, required this.timestamp, required this.sent, required this.id, required this.conversationJid });

  Message copyWith({ String? from, String? body, int? timestamp }) {
    return Message(
      from: from ?? this.from,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      sent: sent,
      conversationJid: conversationJid,
      id: id
    );
  }

  Message.fromJson(Map<String, dynamic> json)
  : from = json["from"],
  body = json["body"],
  timestamp = json["timestamp"],
  sent = json["sent"],
  conversationJid = json["conversationJid"],
  id = json["id"];
  
  Map<String, dynamic> toJson() => {
    "from": from,
    "body": body,
    "timestamp": timestamp,
    "sent": sent,
    "conversationJid": conversationJid,
    "id": id
  };

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [ from, body, timestamp, sent, conversationJid, id ];
}
