import 'dart:io';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/constants.dart';

/// Recreate all notification channels to apply settings that cannot be applied after the notification
/// channel has been created.
Future<void> upgradeV1ToV2NonDb(int _) async {
  // Remove all notification channels, so that we can recreate them
  await MoxplatformPlugin.notifications.deleteNotificationChannels([
    foregroundServiceNotificationChannelId,
    messageNotificationChannelId,
    warningNotificationChannelId,
  ]);

  // Set up notification groups
  await MoxplatformPlugin.notifications.createNotificationGroups(
    [
      NotificationGroup(
        id: messageNotificationGroupId,
        description: 'Chat messages',
      ),
      NotificationGroup(
        id: warningNotificationChannelId,
        description: 'Warnings',
      ),
      NotificationGroup(
        id: foregroundServiceNotificationGroupId,
        description: 'Foreground service',
      ),
    ],
  );

  // Set up the notitifcation channels.
  await MoxplatformPlugin.notifications.createNotificationChannels([
    NotificationChannel(
      title: t.notifications.channels.messagesChannelName,
      description: t.notifications.channels.messagesChannelDescription,
      id: messageNotificationChannelId,
      importance: NotificationChannelImportance.HIGH,
      showBadge: true,
      vibration: true,
      enableLights: true,
    ),
    NotificationChannel(
      title: t.notifications.channels.warningChannelName,
      description: t.notifications.channels.warningChannelDescription,
      id: warningNotificationGroupId,
      importance: NotificationChannelImportance.DEFAULT,
      showBadge: false,
      vibration: true,
      enableLights: false,
    ),
    // The foreground notification channel is only required on Android
    if (Platform.isAndroid)
      NotificationChannel(
        title: t.notifications.channels.serviceChannelName,
        description: t.notifications.channels.serviceChannelDescription,
        id: foregroundServiceNotificationChannelId,
        importance: NotificationChannelImportance.MIN,
        showBadge: false,
        vibration: false,
        enableLights: false,
      ),
  ]);
}
