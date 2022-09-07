import 'package:moxxyv2/service/db/conversation.dart';
import 'package:moxxyv2/service/db/media.dart';
import 'package:moxxyv2/service/db/message.dart';
import 'package:moxxyv2/service/db/roster.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

SharedMedium sharedMediumDbToModel(DBSharedMedium s) {
  return SharedMedium(
    s.id!,
    s.path,
    s.timestamp,
    mime: s.mime,
  );
}

Conversation conversationDbToModel(DBConversation c, bool inRoster, String subscription, ChatState chatState) {
  final media = c.sharedMedia
    .map(sharedMediumDbToModel)
    .toList();
  // ignore: cascade_invocations
  media.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  return Conversation(
    c.title,
    c.lastMessageBody,
    c.avatarUrl,
    c.jid,
    c.unreadCounter,
    c.lastChangeTimestamp,
    media,
    c.id!,
    c.open,
    inRoster,
    subscription,
    c.muted,
    chatState,
  );
}

RosterItem rosterDbToModel(DBRosterItem i) {
  return RosterItem(
    i.id!,
    i.avatarUrl,
    i.avatarHash,
    i.jid,
    i.title,
    i.subscription,
    i.ask,
    i.groups,
  );
}

Message messageDbToModel(DBMessage m) {
  return Message(
    m.sender,
    m.body,
    m.timestamp,
    m.sid,
    m.id!,
    m.conversationJid,
    m.isMedia,
    m.isFileUploadNotification,
    originId: m.originId,
    received: m.received,
    displayed: m.displayed,
    acked: m.acked,
    mediaUrl: m.mediaUrl,
    mediaType: m.mediaType,
    thumbnailData: m.thumbnailData,
    thumbnailDimensions: m.thumbnailDimensions,
    srcUrl: m.srcUrl,
    quotes: m.quotes.value != null ? messageDbToModel(m.quotes.value!) : null,
    errorType: m.errorType,
    filename: m.filename,
  );
}
