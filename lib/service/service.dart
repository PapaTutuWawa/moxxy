import "dart:async";
import "dart:io";

import "package:moxxyv2/shared/logging.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/negotiators/resource_binding.dart";
import "package:moxxyv2/xmpp/negotiators/starttls.dart";
import "package:moxxyv2/xmpp/negotiators/sasl/scram.dart";
import "package:moxxyv2/xmpp/ping.dart";
import "package:moxxyv2/xmpp/xeps/xep_0054.dart";
import "package:moxxyv2/xmpp/xeps/xep_0060.dart";
import "package:moxxyv2/xmpp/xeps/xep_0066.dart";
import "package:moxxyv2/xmpp/xeps/xep_0084.dart";
import "package:moxxyv2/xmpp/xeps/xep_0085.dart";
import "package:moxxyv2/xmpp/xeps/xep_0184.dart";
import "package:moxxyv2/xmpp/xeps/xep_0191.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/negotiator.dart";
import "package:moxxyv2/xmpp/xeps/xep_0280.dart";
import "package:moxxyv2/xmpp/xeps/xep_0333.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";
import "package:moxxyv2/xmpp/xeps/xep_0359.dart";
import "package:moxxyv2/xmpp/xeps/xep_0385.dart";
import "package:moxxyv2/xmpp/xeps/xep_0447.dart";
import "package:moxxyv2/xmpp/xeps/xep_0461.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart";
import "package:moxxyv2/service/managers/roster.dart";
import "package:moxxyv2/service/managers/disco.dart";
import "package:moxxyv2/service/managers/stream.dart";
import "package:moxxyv2/service/moxxmpp/reconnect.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/download.dart";
import "package:moxxyv2/service/notifications.dart";
import "package:moxxyv2/service/avatars.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/service/blocking.dart";
import "package:moxxyv2/service/conversation.dart";
import "package:moxxyv2/service/message.dart";
import "package:moxxyv2/service/events.dart";
import "package:moxxyv2/service/connectivity.dart";
import "package:moxxyv2/ui/events.dart" as ui_events;

import "package:moxplatform/moxplatform.dart";
import "package:moxplatform/types.dart";
import "package:moxlib/awaitabledatasender.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

Future<void> initializeServiceIfNeeded() async {
  final logger = GetIt.I.get<Logger>();
  final handler = MoxplatformPlugin.handler;
  if (await handler.isRunning()) {
    if (kDebugMode) {
      logger.fine("Since kDebugMode is true, waiting 600ms before sending PreStartCommand");
      sleep(const Duration(milliseconds: 600));
    }

    logger.info("Attaching to service...");
    handler.attach(ui_events.handleIsolateEvent);
    logger.info("Done");

    logger.info("Service is running. Sending pre start command");
    handler.getDataSender().sendData(
      PerformPreStartCommand(),
      awaitable: false
    );
  } else {
    logger.info("Service is not running. Initializing service... ");
    await handler.start(
      entrypoint,
      handleUiEvent,
      ui_events.handleIsolateEvent
    );
  }
}

/// A middleware for packing an event into a [DataWrapper] and also
/// logging what we send.
void sendEvent(BackgroundEvent event, { String? id }) {
  // NOTE: *S*erver to *F*oreground
  GetIt.I.get<Logger>().fine("S2F: " + event.toJson().toString());
  GetIt.I.get<BackgroundService>().sendEvent(event, id: id);
}

void setupLogging() {
  //Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
      final logMessageHeader = "[${record.level.name}] (${record.loggerName}) ${record.time}: ";
      String msg = record.message;
      do {
        final tooLong = logMessageHeader.length + msg.length >= 967;
        final line = tooLong ? msg.substring(0, 967 - logMessageHeader.length) : msg;

        if (tooLong) {
          msg = msg.substring(967 - logMessageHeader.length - 2);
        } else {
          msg = "";
        }

        final logMessage = logMessageHeader + line;

        if (GetIt.I.isRegistered<UDPLogger>()) {
          final udp = GetIt.I.get<UDPLogger>();
          if (udp.isEnabled()) {
            udp.sendLog(logMessage, record.time.millisecondsSinceEpoch, record.level.name);
          }
        }

        if (/*kDebugMode*/ true) {
          // ignore: avoid_print
          print(logMessage);
        }
      } while (msg.isNotEmpty);
  });
}

Future<void> initUDPLogger() async {
  final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

  if (prefs.debugEnabled) {
    Logger("initUDPLogger").finest("UDPLogger created");

    final port = prefs.debugPort;
    final ip = prefs.debugIp;
    final passphrase = prefs.debugPassphrase;

    if (port != 0 && ip.isNotEmpty && passphrase.isNotEmpty) {
      GetIt.I.get<UDPLogger>().init(passphrase, ip, port);
    }
  } else {
    GetIt.I.get<UDPLogger>().setEnabled(false);
  }
}

/// The entrypoint for all platforms after the platform specific initilization is done.
Future<void> entrypoint() async {
  // Register the lock
  GetIt.I.registerSingleton<Completer>(Completer());

  // Register singletons
  GetIt.I.registerSingleton<Logger>(Logger("MoxxyService"));
  GetIt.I.registerSingleton<UDPLogger>(UDPLogger());

  setupLogging();
  setupBackgroundEventHandler();

  // Initialize the database
  GetIt.I.registerSingleton<DatabaseService>(DatabaseService());
  await GetIt.I.get<DatabaseService>().initialize();

  GetIt.I.registerSingleton<PreferencesService>(PreferencesService());
  GetIt.I.registerSingleton<BlocklistService>(BlocklistService());
  GetIt.I.registerSingleton<NotificationsService>(NotificationsService());
  GetIt.I.registerSingleton<DownloadService>(DownloadService());
  GetIt.I.registerSingleton<AvatarService>(AvatarService());
  GetIt.I.registerSingleton<RosterService>(RosterService());
  GetIt.I.registerSingleton<ConversationService>(ConversationService());
  GetIt.I.registerSingleton<MessageService>(MessageService());
  final xmpp = XmppService();
  GetIt.I.registerSingleton<XmppService>(xmpp);

  await GetIt.I.get<NotificationsService>().init();
  
  // Init the UDPLogger
  await initUDPLogger();

  final connection = XmppConnection(MoxxyReconnectionPolicy())
    ..registerManagers([
      MoxxyStreamManagementManager(),
      MoxxyDiscoManager(),
      MoxxyRosterManager(),
      PingManager(),
      MessageManager(),
      PresenceManager(),
      CSIManager(),
      DiscoCacheManager(),
      CarbonsManager(),
      PubSubManager(),
      vCardManager(),
      UserAvatarManager(),
      StableIdManager(),
      SIMSManager(),
      MessageDeliveryReceiptManager(),
      ChatMarkerManager(),
      OOBManager(),
      SFSManager(),
      MessageRepliesManager(),
      BlockingManager(),
      ChatStateManager()
    ])
    ..registerFeatureNegotiators([
      ResourceBindingNegotiator(),
      StartTlsNegotiator(),
      StreamManagementNegotiator(),
      CSINegotiator(),
      SaslScramNegotiator(10, "", "", ScramHashType.sha512),
      SaslScramNegotiator(9, "", "", ScramHashType.sha256),
      SaslScramNegotiator(8, "", "", ScramHashType.sha1),
    ]);

  GetIt.I.registerSingleton<XmppConnection>(connection);
  GetIt.I.registerSingleton<ConnectivityService>(ConnectivityService());
  await GetIt.I.get<ConnectivityService>().initialize();

  GetIt.I.get<Logger>().finest("Done with xmpp");
  
  final settings = await xmpp.getConnectionSettings();

  GetIt.I.get<Logger>().finest("Got settings");
  if (settings != null) {
    // The title of the notification will be changed as soon as the connection state
    // of [XmppConnection] changes.
    xmpp.connect(settings, false);
  } else {
    GetIt.I.get<BackgroundService>().setNotification(
      "Moxxy",
      "Idle"
    );
  }

  GetIt.I.get<Logger>().finest("Resolving startup future");
  GetIt.I.get<Completer>().complete();

  sendEvent(ServiceReadyEvent());
}

Future<void> handleUiEvent(Map<String, dynamic>? data) async {
  // NOTE: *F*oreground to *S*ervice
  final log = GetIt.I.get<Logger>();

  if (data == null) {
    log.warning("Received null from the UI isolate. Ignoring...");
    return;
  }
  
  final String id = data["id"]!;
  final command = getCommandFromJson(data["data"]!); 
  if (command == null) {
    log.severe("Unknown command type ${data['type']}");
    return;
  }

  if (command is LoginCommand) {
    final redacted = {
      "id": id,
      "data": LoginCommand(
        jid: command.jid,
        password: "*******",
        useDirectTLS: command.useDirectTLS
      ).toJson()
    };
    log.fine("F2S: " + redacted.toString());
  } else {
    log.fine("F2S: " + data.toString());
  }

  GetIt.I.get<EventHandler>().run(command, extra: id);
}
