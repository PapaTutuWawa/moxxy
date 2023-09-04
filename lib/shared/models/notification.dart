import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/service/pigeon/api.g.dart' as api;

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class Notification with _$Notification {
  factory Notification(
    // The notification id.
    int id,

    // The JID of the conversation the notification belongs to.
    String conversationJid,

    /// The JID of the account that the conversation belongs to.
    String accountJid,

    // The sender title.
    String? sender,

    // The JID of the sender.
    String? senderJid,

    // The path to use as the avatar.
    String? avatarPath,

    // The body text.
    String body,

    // The optional mime type of the media attachment.
    String? mime,

    // The optional mime type of the path attachment.
    String? path,

    // The timestamp of the notification.
    int timestamp,
  ) = _Notification;

  const Notification._();

  /// JSON
  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  api.NotificationMessage toNotificationMessage() {
    return api.NotificationMessage(
      sender: sender,
      jid: senderJid,
      avatarPath: avatarPath,
      content: api.NotificationMessageContent(
        body: body,
        mime: mime,
        path: path,
      ),
      timestamp: timestamp,
    );
  }
}
