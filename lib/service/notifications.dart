import 'dart:math';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxplatform_platform_interface/moxplatform_platform_interface.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart' as modelc;
import 'package:moxxyv2/shared/models/message.dart' as modelm;

const _maxNotificationId = 2147483647;
const _messageChannelKey = 'message_channel';
const _warningChannelKey = 'warning_channel';

class NotificationsService {
  NotificationsService() : _log = Logger('NotificationsService');
  // ignore: unused_field
  final Logger _log;

  Future<void> onNotificationEvent(NotificationEvent event) async {
    if (event.type == NotificationEventType.open) {
      // The notification has been tapped
      sendEvent(
        MessageNotificationTappedEvent(
          conversationJid: event.extra!['conversationJid']!,
          title: event.extra!['title']!,
          avatarPath: event.extra!['avatarPath']!,
        ),
      );
    } else if (event.type == NotificationEventType.markAsRead) {
      // TODO: Handle mark as read
      /*await GetIt.I.get<MessageService>().markMessageAsRead(
            int.parse(action.payload!['id']!),
            // [XmppService.sendReadMarker] will check whether the *SHOULD* send
            // the marker, i.e. if the privacy settings allow it.
            true,
          );*/
    } else if (event.type == NotificationEventType.reply) {
      // TODO: Handle
    }
  }

  Future<void> initialize() async {
    await MoxplatformPlugin.notifications.createNotificationChannel(
      t.notifications.channels.messagesChannelName,
      t.notifications.channels.messagesChannelDescription,
      _messageChannelKey,
      true,
    );
    await MoxplatformPlugin.notifications.createNotificationChannel(
      t.notifications.channels.warningChannelName,
      t.notifications.channels.warningChannelDescription,
      _warningChannelKey,
      false,
    );
    await MoxplatformPlugin.notifications.setI18n(
      NotificationI18nData(
        reply: t.notifications.message.reply,
        markAsRead: t.notifications.message.markAsRead,
        you: t.messages.you,
      ),
    );

    // Listen to notification events
    MoxplatformPlugin.notifications
        .getEventStream()
        .listen(onNotificationEvent);
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

    assert(
      implies(m.fileMetadata?.path != null, m.fileMetadata?.mimeType != null),
      'File metadata has path but no mime type',
    );
    await MoxplatformPlugin.notifications.showMessagingNotification(
      MessagingNotification(
        title: title,
        id: m.id,
        channelId: _messageChannelKey,
        jid: c.jid,
        // TODO: Track the messages
        messages: [
          NotificationMessage(
            sender: title,
            jid: m.sender,
            content: NotificationMessageContent(
              body: body,
              mime: m.fileMetadata?.mimeType,
              path: m.fileMetadata?.path,
            ),
            timestamp: m.timestamp,
            avatarPath: avatarPath,
          ),
        ],
        // TODO
        isGroupchat: false,
        extra: {
          'conversationJid': c.jid,
          'sid': m.sid,
          'title': title,
          'avatarPath': avatarPath,
        },
      ),
    );
  }

  /// Show a notification with the highest priority that uses [title] as the title
  /// and [body] as the body.
  Future<void> showWarningNotification(String title, String body) async {
    await MoxplatformPlugin.notifications.showNotification(
      RegularNotification(
        title: title,
        body: body,
        channelId: _warningChannelKey,
        id: Random().nextInt(_maxNotificationId),
        icon: NotificationIcon.warning,
      ),
    );
  }

  /// Show a notification for a bounced message with erorr [type] for a
  /// message in the chat with [jid].
  Future<void> showMessageErrorNotification(
    String jid,
    MessageErrorType type,
  ) async {
    // Only show the notification for certain errors
    if (![
      MessageErrorType.remoteServerTimeout,
      MessageErrorType.remoteServerNotFound,
      MessageErrorType.serviceUnavailable
    ].contains(type)) {
      return;
    }

    final conversation =
        await GetIt.I.get<ConversationService>().getConversationByJid(jid);
    await MoxplatformPlugin.notifications.showNotification(
      RegularNotification(
        title: t.notifications.errors.messageError.title,
        body: t.notifications.errors.messageError
            .body(conversationTitle: conversation!.title),
        channelId: _warningChannelKey,
        id: Random().nextInt(_maxNotificationId),
        icon: NotificationIcon.error,
      ),
    );
  }

  /// Since all notifications are grouped by the conversation's JID, this function
  /// clears all notifications for [jid].
  Future<void> dismissNotificationsByJid(String jid) async {
    // TODO
    //await AwesomeNotifications().dismissNotificationsByGroupKey(jid);
  }
}
