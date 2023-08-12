import 'dart:convert';
import 'dart:math';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart' as modelc;
import 'package:moxxyv2/shared/models/message.dart' as modelm;
import 'package:moxxyv2/shared/models/notification.dart' as modeln;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

const _maxNotificationId = 2147483647;
const _messageChannelKey = 'message_channel';
const _warningChannelKey = 'warning_channel';

/// Message payload keys.
const _conversationJidKey = 'conversationJid';
const _messageKeyKey = 'key';
const _conversationTitleKey = 'title';
const _conversationAvatarKey = 'avatarPath';

class NotificationsService {
  /// Logging.
  final Logger _log = Logger('NotificationsService');

  /// Called when something happens to the notification, i.e. the actions are triggered or
  /// the notification has been tapped.
  Future<void> onNotificationEvent(NotificationEvent event) async {
    final conversationJid = event.extra![_conversationJidKey]!;
    if (event.type == NotificationEventType.open) {
      // The notification has been tapped
      sendEvent(
        MessageNotificationTappedEvent(
          conversationJid: conversationJid,
          title: event.extra![_conversationTitleKey]!,
          avatarPath: event.extra![_conversationAvatarKey]!,
        ),
      );
    } else if (event.type == NotificationEventType.markAsRead) {
      final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
      final messageKey = modelm.MessageKey.fromJson(
        jsonDecode(event.extra![_messageKeyKey]!) as Map<String, Object>,
      );
      // Mark the message as read
      await GetIt.I.get<MessageService>().markMessageAsRead(
            messageKey.sid,
            messageKey.conversationJid,
            accountJid,
            // [XmppService.sendReadMarker] will check whether the *SHOULD* send
            // the marker, i.e. if the privacy settings allow it.
            true,
          );

      // Update the conversation
      final cs = GetIt.I.get<ConversationService>();
      await cs.createOrUpdateConversation(
        conversationJid,
        accountJid,
        update: (conversation) async {
          final newConversation = await cs.updateConversation(
            conversationJid,
            accountJid,
            unreadCounter: 0,
          );

          // Notify the UI
          sendEvent(
            ConversationUpdatedEvent(
              conversation: newConversation,
            ),
          );

          return newConversation;
        },
      );

      // Clear notifications
      await dismissNotificationsByJid(conversationJid, accountJid);
    } else if (event.type == NotificationEventType.reply) {
      // Save this as a notification so that we can display it later
      assert(
        event.payload != null,
        'Reply payload must be not null',
      );
      final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
      final notification = modeln.Notification(
        event.id,
        conversationJid,
        accountJid,
        null,
        null,
        null,
        event.payload!,
        null,
        null,
        DateTime.now().millisecondsSinceEpoch,
      );
      await GetIt.I.get<DatabaseService>().database.insert(
            notificationsTable,
            notification.toJson(),
          );

      // Send the actual reply
      await GetIt.I.get<XmppService>().sendMessage(
        accountJid: accountJid,
        body: event.payload!,
        recipients: [conversationJid],
      );
    }
  }

  /// Configures the translatable strings on the native side
  /// using locale is currently configured.
  Future<void> configureNotificationI18n() async {
    await MoxplatformPlugin.notifications.setI18n(
      NotificationI18nData(
        reply: t.notifications.message.reply,
        markAsRead: t.notifications.message.markAsRead,
        you: t.messages.you,
      ),
    );
  }

  Future<void> initialize() async {
    // Set up the notitifcation channels.
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

    // Configure i18n
    await configureNotificationI18n();

    // Listen to notification events
    MoxplatformPlugin.notifications
        .getEventStream()
        .listen(onNotificationEvent);
  }

  /// Returns true if a notification should be shown. false otherwise.
  bool shouldShowNotification(String jid) {
    return GetIt.I.get<XmppService>().getCurrentlyOpenedChatJid() != jid;
  }

  /// Queries the notifications for the conversation [jid] from the database.
  Future<List<modeln.Notification>> _getNotificationsForJid(
    String jid,
    String accountJid,
  ) async {
    final rawNotifications =
        await GetIt.I.get<DatabaseService>().database.query(
      notificationsTable,
      where: 'conversationJid = ? AND accountJid = ?',
      whereArgs: [jid, accountJid],
    );
    return rawNotifications.map(modeln.Notification.fromJson).toList();
  }

  Future<int?> _clearNotificationsForJid(String jid, String accountJid) async {
    final db = GetIt.I.get<DatabaseService>().database;

    final result = await db.query(
      notificationsTable,
      where: 'conversationJid = ? AND accountJid = ?',
      whereArgs: [jid, accountJid],
      limit: 1,
    );

    // Assumption that all rows with the same conversationJid have the same id.
    final id = result.isNotEmpty ? result.first['id']! as int : null;
    await db.delete(
      notificationsTable,
      where: 'conversationJid = ? AND accountJid = ?',
      whereArgs: [jid, accountJid],
    );

    return id;
  }

  Future<modeln.Notification> _createNotification(
    modelc.Conversation c,
    modelm.Message m,
    String accountJid,
    String? avatarPath,
    int id, {
    bool shouldOverride = false,
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

    assert(
      implies(m.fileMetadata?.path != null, m.fileMetadata?.mimeType != null),
      'File metadata has path but no mime type',
    );

    /// Use the resource (nick) when the chat is a groupchat
    final senderJid = m.senderJid;
    final senderTitle = c.isGroupchat
        ? senderJid.resource
        : await c.titleWithOptionalContactService;

    // Add to the database
    final newNotification = modeln.Notification(
      id,
      c.jid,
      accountJid,
      senderTitle,
      senderJid.toString(),
      (avatarPath?.isEmpty ?? false) ? null : avatarPath,
      body,
      m.fileMetadata?.mimeType,
      m.fileMetadata?.path,
      m.timestamp,
    );
    await GetIt.I.get<DatabaseService>().database.insert(
          notificationsTable,
          newNotification.toJson(),
          conflictAlgorithm: shouldOverride ? ConflictAlgorithm.replace : null,
        );
    return newNotification;
  }

  /// Indicates whether we're allowed to show notifications on devices >= Android 13.
  Future<bool> _canDoNotifications() async {
    return Permission.notification.isGranted;
  }

  /// When a notification is already visible, then build a new notification based on [c] and [m],
  /// update the database state and tell the OS to show the notification again.
  // TODO(Unknown): What about systems that cannot do this (Linux, OS X, Windows)?
  Future<void> updateNotification(
    modelc.Conversation c,
    modelm.Message m,
    String accountJid,
  ) async {
    if (!(await _canDoNotifications())) {
      _log.warning(
        'updateNotification: Notifications permission not granted. Doing nothing.',
      );
      return;
    }

    final notifications = await _getNotificationsForJid(c.jid, accountJid);
    final id = notifications.first.id;
    // TODO(Unknown): Handle groupchat member avatars
    final notification = await _createNotification(
      c,
      m,
      accountJid,
      c.isGroupchat ? null : c.avatarPathWithOptionalContact,
      id,
      shouldOverride: true,
    );

    await MoxplatformPlugin.notifications.showMessagingNotification(
      MessagingNotification(
        title: await c.titleWithOptionalContactService,
        id: id,
        channelId: _messageChannelKey,
        jid: c.jid,
        messages: [
          ...notifications.map((n) {
            // Based on the table's composite primary key
            if (n.id == notification.id &&
                n.conversationJid == notification.conversationJid &&
                n.senderJid == notification.senderJid &&
                n.timestamp == notification.timestamp) {
              return notification.toNotificationMessage();
            }

            return n.toNotificationMessage();
          }),
        ],
        isGroupchat: c.isGroupchat,
        extra: {
          _conversationJidKey: c.jid,
          _messageKeyKey: jsonEncode(m.messageKey),
          _conversationTitleKey: await c.titleWithOptionalContactService,
          _conversationAvatarKey: await c.avatarPathWithOptionalContactService,
        },
      ),
    );
  }

  /// Show a notification for a message [m] grouped by its conversationJid
  /// attribute. If the message is a media message, i.e. mediaUrl != null and isMedia == true,
  /// then Android's BigPicture will be used.
  Future<void> showNotification(
    modelc.Conversation c,
    modelm.Message m,
    String accountJid,
    String title, {
    String? body,
  }) async {
    if (!(await _canDoNotifications())) {
      _log.warning(
        'showNotification: Notifications permission not granted. Doing nothing.',
      );
      return;
    }

    final notifications = await _getNotificationsForJid(c.jid, accountJid);
    final id = notifications.isNotEmpty
        ? notifications.first.id
        : Random().nextInt(_maxNotificationId);
    await MoxplatformPlugin.notifications.showMessagingNotification(
      MessagingNotification(
        title: title,
        id: id,
        channelId: _messageChannelKey,
        jid: c.jid,
        messages: [
          ...notifications.map((n) => n.toNotificationMessage()),
          // TODO(Unknown): Handle groupchat member avatars
          (await _createNotification(
            c,
            m,
            accountJid,
            c.isGroupchat ? null : await c.avatarPathWithOptionalContactService,
            id,
          ))
              .toNotificationMessage(),
        ],
        isGroupchat: c.isGroupchat,
        extra: {
          _conversationJidKey: c.jid,
          _messageKeyKey: jsonEncode(m.messageKey),
          _conversationTitleKey: await c.titleWithOptionalContactService,
          _conversationAvatarKey: await c.avatarPathWithOptionalContactService,
        },
      ),
    );
  }

  /// Show a notification with the highest priority that uses [title] as the title
  /// and [body] as the body.
  Future<void> showWarningNotification(String title, String body) async {
    if (!(await _canDoNotifications())) {
      _log.warning(
        'showWarningNotification: Notifications permission not granted. Doing nothing.',
      );
      return;
    }

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
    String accountJid,
    MessageErrorType type,
  ) async {
    if (!(await _canDoNotifications())) {
      _log.warning(
        'showMessageErrorNotification: Notifications permission not granted. Doing nothing.',
      );
      return;
    }

    // Only show the notification for certain errors
    if (![
      MessageErrorType.remoteServerTimeout,
      MessageErrorType.remoteServerNotFound,
      MessageErrorType.serviceUnavailable
    ].contains(type)) {
      return;
    }

    final conversation = await GetIt.I
        .get<ConversationService>()
        .getConversationByJid(jid, accountJid);
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
  Future<void> dismissNotificationsByJid(String jid, String accountJid) async {
    final id = await _clearNotificationsForJid(jid, accountJid);
    if (id != null) {
      await MoxplatformPlugin.notifications.dismissNotification(id);
    }
  }

  /// Dismisses all notifications for the context of [accountJid].
  Future<void> dismissAllNotifications(String accountJid) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final ids = await db.query(
      notificationsTable,
      where: 'accountJid = ?',
      whereArgs: [accountJid],
      columns: ['id'],
      distinct: true,
    );

    // Dismiss the notification
    for (final idRaw in ids) {
      await MoxplatformPlugin.notifications.dismissNotification(idRaw['id']! as int);
    }

    // Remove database entries
    await db.delete(
      notificationsTable,
      where: 'accountJid = ?',
      whereArgs: [accountJid],
    );
  }

  /// Requests the avatar path from [XmppStateService] and configures the notification plugin
  /// accordingly, if the avatar path is not null. If it is null, this method does nothing.
  Future<void> maybeSetAvatarFromState() async {
    final avatarPath =
        (await GetIt.I.get<XmppStateService>().getXmppState()).avatarUrl;
    if (avatarPath.isNotEmpty) {
      await MoxplatformPlugin.notifications
          .setNotificationSelfAvatar(avatarPath);
    }
  }
}
