import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/service/pigeon/api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/org/moxxy/moxxyv2/plugin/Api.kt',
    kotlinOptions: KotlinOptions(
      package: 'org.moxxy.moxxyv2.plugin',
    ),
  ),
)
class NotificationMessageContent {
  const NotificationMessageContent(
    this.body,
    this.mime,
    this.path,
  );

  /// The textual body of the message.
  final String? body;

  /// The path and mime type of the media to show.
  final String? mime;
  final String? path;
}

class NotificationMessage {
  const NotificationMessage(
    this.sender,
    this.content,
    this.jid,
    this.timestamp,
    this.avatarPath, {
    this.groupId,
  });

  /// The grouping key for the notification.
  final String? groupId;

  /// The sender of the message.
  final String? sender;

  /// The jid of the sender.
  final String? jid;

  /// The body of the message.
  final NotificationMessageContent content;

  /// Milliseconds since epoch.
  final int timestamp;

  /// The path to the avatar to use
  final String? avatarPath;
}

class MessagingNotification {
  const MessagingNotification(this.title, this.id, this.jid, this.messages,
      this.channelId, this.isGroupchat, this.extra,
      {this.groupId});

  /// The title of the conversation.
  final String title;

  /// The id of the notification.
  final int id;

  /// The id of the notification channel the notification should appear on.
  final String channelId;

  /// The JID of the chat in which the notifications happen.
  final String jid;

  /// Messages to show.
  final List<NotificationMessage?> messages;

  /// Flag indicating whether this notification is from a groupchat or not.
  final bool isGroupchat;

  /// The id for notification grouping.
  final String? groupId;

  /// Additional data to include.
  final Map<String?, String?>? extra;
}

enum NotificationIcon {
  warning,
  error,
  none,
}

class RegularNotification {
  const RegularNotification(
      this.title, this.body, this.channelId, this.id, this.icon,
      {this.groupId});

  /// The title of the notification.
  final String title;

  /// The body of the notification.
  final String body;

  /// The id of the channel to show the notification on.
  final String channelId;

  /// The id for notification grouping.
  final String? groupId;

  /// The id of the notification.
  final int id;

  /// The icon to use.
  final NotificationIcon icon;
}

enum NotificationEventType {
  markAsRead,
  reply,
  open,
}

class NotificationEvent {
  const NotificationEvent(
    this.id,
    this.jid,
    this.type,
    this.payload,
    this.extra,
  );

  /// The notification id.
  final int id;

  /// The JID the notification was for.
  final String jid;

  /// The type of event.
  final NotificationEventType type;

  /// An optional payload.
  /// - type == NotificationType.reply: The reply message text.
  /// Otherwise: undefined.
  final String? payload;

  /// Extra data. Only set when type == NotificationType.reply.
  final Map<String?, String?>? extra;
}

class NotificationI18nData {
  const NotificationI18nData(this.reply, this.markAsRead, this.you);

  /// The content of the reply button.
  final String reply;

  /// The content of the "mark as read" button.
  final String markAsRead;

  /// The text to show when *you* reply.
  final String you;
}

class NotificationGroup {
  const NotificationGroup(this.id, this.description);
  final String id;
  final String description;
}

enum NotificationChannelImportance { MIN, HIGH, DEFAULT }

class NotificationChannel {
  const NotificationChannel(
    this.id,
    this.title,
    this.description, {
    this.importance = NotificationChannelImportance.DEFAULT,
    this.showBadge = true,
    this.groupId,
    this.vibration = true,
    this.enableLights = true,
  });
  final String title;
  final String description;
  final String id;
  final NotificationChannelImportance importance;
  final bool showBadge;
  final String? groupId;
  final bool vibration;
  final bool enableLights;
}

enum FilePickerType {
  image,
  video,
  imageAndVideo,
  generic,
}

@HostApi()
abstract class MoxxyApi {
  /// Notification APIs
  void createNotificationGroups(List<NotificationGroup> groups);
  void deleteNotificationGroups(List<String> ids);
  void createNotificationChannels(List<NotificationChannel> channels);
  void deleteNotificationChannels(List<String> ids);
  void showMessagingNotification(MessagingNotification notification);
  void showNotification(RegularNotification notification);
  void dismissNotification(int id);
  void setNotificationSelfAvatar(String path);
  void setNotificationI18n(NotificationI18nData data);

  @async
  List<String> pickFiles(FilePickerType type, bool multiple);

  @async
  Uint8List? pickFileWithData(FilePickerType type);

  // Stubs for generating event classes
  void notificationStub(NotificationEvent event);
}
