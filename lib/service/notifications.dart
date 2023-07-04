import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart' as modelc;
import 'package:moxxyv2/shared/models/message.dart' as modelm;

const _maxNotificationId = 2147483647;
const _messageChannelKey = 'message_channel';
const _warningChannelKey = 'warning_channel';
const _notificationActionKeyRead = 'markAsRead';
const _notificationActionKeyReply = 'reply';

// TODO(Unknown): Add resolution dependent drawables for the notification icon
class NotificationsService {
  NotificationsService() : _log = Logger('NotificationsService');
  // ignore: unused_field
  final Logger _log;

  @pragma('vm:entry-point')
  static Future<void> onReceivedAction(ReceivedAction action) async {
    final logger = Logger('NotificationHandler');

    if (action.buttonKeyPressed.isEmpty && action.buttonKeyInput.isEmpty) {
      // The notification has been tapped
      sendEvent(
        MessageNotificationTappedEvent(
          conversationJid: action.payload!['conversationJid']!,
          title: action.payload!['title']!,
          avatarPath: action.payload!['avatarPath']!,
        ),
      );
    } else if (action.buttonKeyPressed == _notificationActionKeyRead) {
      await GetIt.I.get<MessageService>().markMessageAsRead(
            int.parse(action.payload!['id']!),
            // [XmppService.sendReadMarker] will check whether the *SHOULD* send
            // the marker, i.e. if the privacy settings allow it.
            true,
          );
    } else {
      logger.warning(
        'Received unknown notification action key ${action.buttonKeyPressed}',
      );
    }
  }

  Future<void> initialize() async {
    final an = AwesomeNotifications();
    await an.initialize(
      'resource://drawable/ic_service_icon',
      [
        NotificationChannel(
          channelKey: _messageChannelKey,
          channelName: t.notifications.channels.messagesChannelName,
          channelDescription:
              t.notifications.channels.messagesChannelDescription,
        ),
        NotificationChannel(
          channelKey: _warningChannelKey,
          channelName: t.notifications.channels.warningChannelName,
          channelDescription:
              t.notifications.channels.warningChannelDescription,
        ),
      ],
      debug: kDebugMode,
    );
    await an.setListeners(
      onActionReceivedMethod: onReceivedAction,
    );
  }

  /// Returns true if a notification should be shown. false otherwise.
  bool shouldShowNotification(String jid) {
    return GetIt.I.get<XmppService>().getCurrentlyOpenedChatJid() != jid;
  }

  /// Show a notification for a message [m] grouped by its conversationJid
  /// attribute. If the message is a media message, i.e. mediaUrl != null and isMedia == true,
  /// then Android's BigPicture will be used.
  Future<void> showNotification(
    modelc.Conversation c,
    modelm.Message m,
    String title, {
    String? body,
  }) async {
    // See https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart#L1293
    String body;
    if (m.stickerPackId != null) {
      body = t.messages.sticker;
    } else if (m.isMedia) {
      body = mimeTypeToEmoji(m.fileMetadata!.mimeType);
    } else {
      body = m.body;
    }

    final css = GetIt.I.get<ContactsService>();
    final contactIntegrationEnabled = await css.isContactIntegrationEnabled();
    final title =
        contactIntegrationEnabled ? c.contactDisplayName ?? c.title : c.title;
    final avatarPath = contactIntegrationEnabled
        ? c.contactAvatarPath ?? c.avatarPath
        : c.avatarPath;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: m.id,
        groupKey: c.jid,
        channelKey: _messageChannelKey,
        summary: title,
        title: title,
        body: body,
        largeIcon: avatarPath.isNotEmpty ? 'file://$avatarPath' : null,
        notificationLayout: m.isThumbnailable
            ? NotificationLayout.BigPicture
            : NotificationLayout.Messaging,
        category: NotificationCategory.Message,
        bigPicture: m.isThumbnailable ? 'file://${m.fileMetadata!.path}' : null,
        payload: <String, String>{
          'conversationJid': c.jid,
          'sid': m.sid,
          'title': title,
          'avatarPath': avatarPath,
          'messageId': m.id.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: _notificationActionKeyReply,
          label: t.notifications.message.reply,
          requireInputText: true,
          autoDismissible: false,
        ),
        NotificationActionButton(
          key: _notificationActionKeyRead,
          label: t.notifications.message.markAsRead,
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
