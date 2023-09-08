import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/quirks/quirks.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/org/moxxy/moxxyv2/quirks/NotificationsQuirks.kt',
    kotlinOptions: KotlinOptions(
      package: 'org.moxxy.moxxyv2.quirks',
    ),
  ),
)

enum QuirkNotificationEventType {
  markAsRead,
  reply,
  open,
}

class QuirkNotificationEvent {
  const QuirkNotificationEvent(
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
  final QuirkNotificationEventType type;

  /// An optional payload.
  /// - type == NotificationType.reply: The reply message text.
  /// Otherwise: undefined.
  final String? payload;

  /// Extra data. Only set when type == NotificationType.reply.
  final Map<String?, String?>? extra;
}

@HostApi()
abstract class MoxxyQuirkApi {
  QuirkNotificationEvent? earlyNotificationEventQuirk();
}
