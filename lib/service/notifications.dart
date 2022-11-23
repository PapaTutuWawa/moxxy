import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart' as modelc;
import 'package:moxxyv2/shared/models/message.dart' as modelm;

const _maxNotificationId = 2147483647;
const _messageChannelKey = 'message_channel';
const _warningChannelKey = 'warning_channel';

// TODO(Unknown): Add resolution dependent drawables for the notification icon
class NotificationsService {
  NotificationsService() : _log = Logger('NotificationsService');
  // ignore: unused_field
  final Logger _log;

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_service_icon',
      [
        NotificationChannel(
          channelKey: _messageChannelKey,
          channelName: t.notifications.channels.messagesChannelName,
          channelDescription: t.notifications.channels.messagesChannelDescription,
        ),
        NotificationChannel(
          channelKey: _warningChannelKey,
          channelName: t.notifications.channels.warningChannelName,
          channelDescription: t.notifications.channels.warningChannelDescription,
        ),
      ],
      debug: kDebugMode,
    );
   }

  /// Returns true if a notification should be shown. false otherwise.
  bool shouldShowNotification(String jid) {
    return GetIt.I.get<XmppService>().getCurrentlyOpenedChatJid() != jid;
  }
  
  /// Show a notification for a message [m] grouped by its conversationJid
  /// attribute. If the message is a media message, i.e. mediaUrl != null and isMedia == true,
  /// then Android's BigPicture will be used.
  Future<void> showNotification(modelc.Conversation c, modelm.Message m, String title, { String? body }) async {
    // TODO(Unknown): Keep track of notifications to create a summary notification
    // See https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart#L1293
    final body = m.isMedia ?
      mimeTypeToEmoji(m.mediaType) :
      m.body;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: m.id,
        groupKey: c.jid,
        channelKey: _messageChannelKey,
        summary: c.title,
        title: c.title,
        body: body,
        largeIcon: c.avatarUrl.isNotEmpty ? 'file://${c.avatarUrl}' : null,
        notificationLayout: m.thumbnailable ?
          NotificationLayout.BigPicture :
          NotificationLayout.Messaging,
        category: NotificationCategory.Message,
        bigPicture: m.thumbnailable ? 'file://${m.mediaUrl}' : null,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: t.notifications.message.reply,
          requireInputText: true,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: 'READ',
          label: t.notifications.message.markAsRead,
          requireInputText: true,
        )
      ],
    );
  }

  /// Show a notification with the highest priority that uses [title] as the title
  /// and [body] as the body.
  // TODO(Unknown): Use the warning icon as the notification icon
  Future<void> showWarningNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(_maxNotificationId),
        title: title,
        body: body,
        channelKey: _warningChannelKey,
      ),
    );
  }

  /// Since all notifications are grouped by the conversation's JID, this function
  /// clears all notifications for [jid].
  Future<void> dismissNotificationsByJid(String jid) async {
    await AwesomeNotifications().dismissNotificationsByGroupKey(jid);
  }
}
