import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/constants.dart';

/// Recreate all notification channels to apply settings that cannot be applied after the notification
/// channel has been created.
Future<void> upgradeV1ToV2NonDb(int _) async {
  // Ensure that we can use the device locale
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  final api = MoxxyNotificationsApi();

  // Remove all notification channels, so that we can recreate them
  await api.deleteNotificationChannels([
    'FOREGROUND_DEFAULT',
    'message_channel',
    'warning_channel',
    // Not sure where this one comes from
    'warning',
  ]);

  // Set up notification groups
  await api.createNotificationGroups(
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
  await api.createNotificationChannels([
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
      id: warningNotificationChannelId,
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
