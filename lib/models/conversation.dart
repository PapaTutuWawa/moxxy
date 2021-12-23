class Conversation {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;

  const Conversation({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid });

  Conversation copyWith({ String? lastMessageBody }) {
    return Conversation(
      title: this.title,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      avatarUrl: this.avatarUrl,
      jid: this.jid
    );
  }
}
