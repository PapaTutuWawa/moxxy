class Conversation {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;
  final int unreadCounter;

  const Conversation({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid, required this.unreadCounter });

  Conversation copyWith({ String? lastMessageBody, int? unreadCounter, int unreadDelta = 0 }) {
    return Conversation(
      title: this.title,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      avatarUrl: this.avatarUrl,
      jid: this.jid,
      unreadCounter: (unreadCounter ?? this.unreadCounter) + unreadDelta
    );
  }
}
