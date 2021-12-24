import "dart:collection";

class Conversation {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;
  final int unreadCounter;
  // TODO: Maybe have a model for this, but this should be enough
  final List<String> sharedMediaPaths;

  const Conversation({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid, required this.unreadCounter, required this.sharedMediaPaths });

  Conversation copyWith({ String? lastMessageBody, int? unreadCounter, int unreadDelta = 0, List<String>? sharedMediaPaths }) {
    return Conversation(
      title: this.title,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      avatarUrl: this.avatarUrl,
      jid: this.jid,
      unreadCounter: (unreadCounter ?? this.unreadCounter) + unreadDelta,
      sharedMediaPaths: sharedMediaPaths ?? this.sharedMediaPaths
    );
  }
}
