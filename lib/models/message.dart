class Message {
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
      sent: this.sent,
      conversationJid: this.conversationJid,
      id: this.id
    );
  }
}
