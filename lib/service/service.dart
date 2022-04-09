import "dart:async";

import "package:moxxyv2/shared/logging.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0054.dart";
import "package:moxxyv2/xmpp/xeps/xep_0060.dart";
import "package:moxxyv2/xmpp/xeps/xep_0066.dart";
import "package:moxxyv2/xmpp/xeps/xep_0084.dart";
import "package:moxxyv2/xmpp/xeps/xep_0184.dart";
import "package:moxxyv2/xmpp/xeps/xep_0191.dart";
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
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/download.dart";
import "package:moxxyv2/service/notifications.dart";
import "package:moxxyv2/service/avatars.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/service/blocking.dart";
import "package:moxxyv2/service/events.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";
import "package:logging/logging.dart";
import "package:uuid/uuid.dart";

import "package:moxxyv2/service/db/conversation.dart";
import "package:moxxyv2/service/db/roster.dart";
import "package:moxxyv2/service/db/message.dart";
import "package:moxxyv2/service/db/media.dart";

Future<void> initializeServiceIfNeeded() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = FlutterBackgroundService();
  if (await service.isServiceRunning()) {
    GetIt.I.get<Logger>().info("Stopping background service");

    if (kDebugMode) {
      //service.stopBackgroundService();
    } else {
      return;
    }
  }

  GetIt.I.get<Logger>().info("Initializing service");
  await initializeService();
}

typedef EventMiddlewareType = void Function(BackgroundEvent, { String id });

/// A middleware for packing an event into a [DataWrapper] and also
/// logging what we send.
void sendEvent(BackgroundEvent event, { String? id }) {
  final json = event.toJson();
  final data = DataWrapper(
    id ?? Uuid().v4(),
    event
  );
  // NOTE: *S*erver to *F*oreground
  GetIt.I.get<Logger>().fine("S2F: " + data.toString());
  
  GetIt.I.get<FlutterBackgroundService>().sendData(data.toJson());
}

// TODO: Move into the database service
Future<Isar> openDatabase() async {
  final dir = await getApplicationSupportDirectory();
  return await Isar.open(
    schemas: [
      DBConversationSchema,
      DBRosterItemSchema,
      DBMessageSchema,
      DBSharedMediumSchema
    ],
    directory: dir.path
  );
}

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) { 
      final logMessage = "[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}";
      if (GetIt.I.isRegistered<UDPLogger>()) {
        final udp = GetIt.I.get<UDPLogger>();
        if (udp.isEnabled()) {
          udp.sendLog(logMessage, record.time.millisecondsSinceEpoch, record.level.name);
        }
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print(logMessage);
      }
  });
}

Future<void> initUDPLogger() async {
  final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

  if (prefs.debugEnabled) {
    GetIt.I.get<Logger>().finest("UDPLogger created");

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

/// Entrypoint for the background service
void onStart() {
  WidgetsFlutterBinding.ensureInitialized();

  setupLogging();
  setupBackgroundEventHandler();

  final service = FlutterBackgroundService();
  GetIt.I.registerSingleton<FlutterBackgroundService>(service);
  GetIt.I.registerSingleton<Logger>(Logger("XmppService"));
  service.onDataReceived.listen(handleEvent);
  service.setNotificationInfo(title: "Moxxy", content: "Connecting...");

  GetIt.I.get<Logger>().finest("Running...");

  (() async {
      // Register singletons
      GetIt.I.registerSingleton<UDPLogger>(UDPLogger());
      GetIt.I.registerSingleton<DatabaseService>(DatabaseService(await openDatabase()));
      GetIt.I.registerSingleton<PreferencesService>(PreferencesService());
      GetIt.I.registerSingleton<BlocklistService>(BlocklistService());
      GetIt.I.registerSingleton<NotificationsService>(NotificationsService());
      GetIt.I.registerSingleton<DownloadService>(DownloadService());
      GetIt.I.registerSingleton<AvatarService>(AvatarService());
      GetIt.I.registerSingleton<RosterService>(RosterService());
      final xmpp = XmppService();
      GetIt.I.registerSingleton<XmppService>(xmpp);

      await GetIt.I.get<NotificationsService>().init();
      
      // Init the UDPLogger
      await initUDPLogger();

      final connection = XmppConnection();
      connection.registerManagers([
          MoxxyStreamManagementManager(),
          MoxxyDiscoManager(),
          MoxxyRosterManager(),
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
          BlockingManager()
      ]);
      GetIt.I.registerSingleton<XmppConnection>(connection);

      final settings = await xmpp.getConnectionSettings();

      if (settings != null && settings.jid != null && settings.password != null) {
        xmpp.connect(settings, false);
      }
  })();
}

Future<FlutterBackgroundService> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    // TODO: iOS
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onBackground: () {},
      onForeground: () {}
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true
    )
  );

  return service;
}

void setupBackgroundEventHandler() {
  final handler = EventHandler();
  handler.addMatchers([
      EventTypeMatcher<LoginCommand>(performLoginHandler),
      EventTypeMatcher<PerformPreStartCommand>(performPreStart),
      EventTypeMatcher<AddConversationCommand>(performAddConversation),
      EventTypeMatcher<GetMessagesForJidCommand>(performGetMessagesForJid),
      EventTypeMatcher<SetOpenConversationCommand>(performSetOpenConversation),
      EventTypeMatcher<SendMessageCommand>(performSendMessage),
      EventTypeMatcher<BlockJidCommand>(performBlockJid),
      EventTypeMatcher<UnblockJidCommand>(performUnblockJid),
      EventTypeMatcher<UnblockAllCommand>(performUnblockAll),
      EventTypeMatcher<SetCSIStateCommand>(performSetCSIState),
      EventTypeMatcher<SetPreferencesCommand>(performSetPreferences),
      EventTypeMatcher<RequestDownloadCommand>(performRequestDownload),
      EventTypeMatcher<SetAvatarCommand>(performSetAvatar),
      EventTypeMatcher<SetShareOnlineStatusCommand>(performSetShareOnlineStatus),
      EventTypeMatcher<CloseConversationCommand>(performCloseConversation)
  ]);

  GetIt.I.registerSingleton<EventHandler>(handler);
}

void handleEvent(Map<String, dynamic>? data) {
  // NOTE: *F*oreground to *S*ervice
  final log = GetIt.I.get<Logger>();

  if (data == null) {
    log.warning("Received null from the UI isolate. Ignoring...");
    return;
  }

  log.fine("F2S: " + data.toString());
  
  final String id = data["id"]!;
  final command = getCommandFromJson(data["data"]!);

  if (command == null) {
    log.severe("Unknown command type ${data['type']}");
    return;
  }

  GetIt.I.get<EventHandler>().run(command, extra: id);
}
