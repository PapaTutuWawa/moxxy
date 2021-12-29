import "dart:collection";

import "package:isar/isar.dart";

class Conversation {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;
  final int id;
  final int unreadCounter;
  final int lastChangeTimestamp; // NOTE: In milliseconds since Epoch or -1 if none has ever happened
  // TODO: Maybe have a model for this, but this should be enough
  final List<String> sharedMediaPaths;
  final bool open;

  const Conversation({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid, required this.unreadCounter, required this.lastChangeTimestamp, required this.sharedMediaPaths, required this.id, required this.open });

  Conversation copyWith({ String? lastMessageBody, int? unreadCounter, int unreadDelta = 0, List<String>? sharedMediaPaths, int? lastChangeTimestamp, bool? open }) {
    return Conversation(
      title: this.title,
      lastMessageBody: lastMessageBody ?? this.lastMessageBody,
      avatarUrl: this.avatarUrl,
      jid: this.jid,
      unreadCounter: (unreadCounter ?? this.unreadCounter) + unreadDelta,
      sharedMediaPaths: sharedMediaPaths ?? this.sharedMediaPaths,
      lastChangeTimestamp: lastChangeTimestamp ?? this.lastChangeTimestamp,
      open: open ?? this.open,
      id: this.id
    );
  }
}
