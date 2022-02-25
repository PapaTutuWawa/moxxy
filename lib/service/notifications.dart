import "package:moxxyv2/shared/models/message.dart" as model;

import "package:logging/logging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:get_it/get_it.dart";

// TODO: Add resolution dependent drawables for the notification icon
class NotificationsService {
  // ignore: unused_field
  final Logger _log;

  NotificationsService() : _log = Logger("NotificationsService");

  Future<void> init() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings("app_icon"),
      //ios: IOSInitilizationSettings(...)
    );

    // TODO: Callback
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    GetIt.I.registerSingleton<FlutterLocalNotificationsPlugin>(flutterLocalNotificationsPlugin);
  }

  /// Show a notification for a message [m] grouped by its [conversationJid]
  /// attribute. If the message is a media message, i.e. mediaUrl != null and isMedia == true,
  /// then Android's BigPicture will be used.
  Future<void> showNotification(model.Message m, String title) async {
    // TODO: Keep track of notifications to create a summary notification
    // See https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart#L1293
    final androidDetails = AndroidNotificationDetails(
      "message_channel", "Message channel",
      channelDescription: "The notification channel for received messages",
      styleInformation: (m.isMedia && m.mediaUrl != null) ? BigPictureStyleInformation(
        FilePathAndroidBitmap(m.mediaUrl!)
      ) : null,
      groupKey: m.conversationJid
    );
    final body = (m.isMedia && m.mediaUrl != null) ? "📷 Image" : m.body;
    final details = NotificationDetails(android: androidDetails);
    await GetIt.I.get<FlutterLocalNotificationsPlugin>().show(
      m.id, title, body, details
    );
  }
}
