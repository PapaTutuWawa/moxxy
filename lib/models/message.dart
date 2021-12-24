class Message {
  final String body;
  final int timestamp; // NOTE: Milliseconds since Epoch
  final String from;
  final bool sent;

  const Message({ required this.from, required this.body, required this.timestamp, required this.sent });

  Message copyWith({ String? from, String? body, int? timestamp }) {
    return Message(
      from: from ?? this.from,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      sent: this.sent
    );
  }
}
