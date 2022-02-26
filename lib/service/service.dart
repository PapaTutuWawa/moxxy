import "dart:async";

import "package:moxxyv2/shared/logging.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart";
import "package:moxxyv2/service/managers/roster.dart";
import "package:moxxyv2/service/managers/disco.dart";
import "package:moxxyv2/service/managers/stream.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/download.dart";
import "package:moxxyv2/service/notifications.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";
import "package:logging/logging.dart";

import "package:moxxyv2/service/db/conversation.dart";
import "package:moxxyv2/service/db/roster.dart";
import "package:moxxyv2/service/db/message.dart";

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

void Function(BaseIsolateEvent) sendDataMiddleware(FlutterBackgroundService srv) {
  return (data) {
    final json = data.toJson();
    // NOTE: *S*erver to *F*oreground
    GetIt.I.get<Logger>().fine("S2F: " + json.toString());

    srv.sendData(json);
  };
}

Future<void> performPreStart(void Function(BaseIsolateEvent) sendData) async {
  final xmpp = GetIt.I.get<XmppService>();
  final account = await xmpp.getAccountData();
  final settings = await xmpp.getConnectionSettings();
  final state = await xmpp.getXmppState();

  GetIt.I.get<Logger>().finest("account != null: " + (account != null).toString());
  GetIt.I.get<Logger>().finest("settings != null: " + (settings != null).toString());

  if (account!= null && settings != null) {
    await GetIt.I.get<RosterService>().loadRosterFromDatabase();

    sendData(PreStartResultEvent(
        state: "logged_in",
        jid: account.jid,
        displayName: account.displayName,
        avatarUrl: account.avatarUrl,
        debugEnabled: state.debugEnabled
    ));
  } else {
    sendData(PreStartResultEvent(
        state: "not_logged_in",
        debugEnabled: state.debugEnabled
    ));
  }
}

Future<Isar> openDatabase() async {
  final dir = await getApplicationSupportDirectory();
  return await Isar.open(
    schemas: [
      DBConversationSchema,
      DBRosterItemSchema,
      DBMessageSchema
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
  final state = await GetIt.I.get<XmppService>().getXmppState();

  if (state.debugEnabled) {
    GetIt.I.get<Logger>().finest("UDPLogger created");

    final port = state.debugPort;
    final ip = state.debugIp;
    final passphrase = state.debugPassphrase;

    if (port != 0 && ip.isNotEmpty && passphrase.isNotEmpty) {
      GetIt.I.get<UDPLogger>().init(passphrase, ip, port);
    }
  } else {
    GetIt.I.get<UDPLogger>().setEnabled(false);
  }
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();

  setupLogging();
  GetIt.I.registerSingleton<Logger>(Logger("XmppService"));

  final service = FlutterBackgroundService();
  service.onDataReceived.listen(handleEvent);
  service.setNotificationInfo(title: "Moxxy", content: "Connecting...");

  GetIt.I.get<Logger>().finest("Running...");

  GetIt.I.registerSingleton<NotificationsService>(NotificationsService());

  (() async {
      await GetIt.I.get<NotificationsService>().init();

      final middleware = sendDataMiddleware(service);

      // Register singletons
      GetIt.I.registerSingleton<UDPLogger>(UDPLogger());

      final db = DatabaseService(isar: await openDatabase(), sendData: middleware);
      GetIt.I.registerSingleton<DatabaseService>(db); 

      final xmpp = XmppService(sendData: (data) {
          if (data is ConnectionStateEvent) {
            if (data.state == XmppConnectionState.connected.toString().split(".")[1]) {
              FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Ready to receive messages");
            } else if (data.state == XmppConnectionState.connecting.toString().split(".")[1]) {
              FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Connecting...");
            } else {
              FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Disconnected");
            }
          }

          middleware(data);
      });
      GetIt.I.registerSingleton<XmppService>(xmpp);
      GetIt.I.registerSingleton<DownloadService>(DownloadService(middleware));

      // Init the UDPLogger
      await initUDPLogger();

      GetIt.I.registerSingleton<RosterService>(RosterService(sendData: middleware));

      final connection = XmppConnection();
      connection.registerManager(MoxxyStreamManagementManager());
      connection.registerManager(MoxxyDiscoManager());
      connection.registerManager(MessageManager());
      connection.registerManager(MoxxyRosterManger());
      connection.registerManager(PresenceManager());
      connection.registerManager(CSIManager());
      connection.registerManager(DiscoCacheManager());
      GetIt.I.registerSingleton<XmppConnection>(connection);

      final account = await xmpp.getAccountData();
      final settings = await xmpp.getConnectionSettings();

      if (account!= null && settings != null) {
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

void handleEvent(Map<String, dynamic>? data) {
  // NOTE: *F*oreground to *S*ervice
  GetIt.I.get<Logger>().fine("F2S: " + data.toString());

  switch (data!["type"]) {
    case "LoadConversationsAction": {
      GetIt.I.get<DatabaseService>().loadConversations();
    }
    break;
    case "PerformLoginAction": {
      GetIt.I.get<Logger>().fine("Performing login");
      GetIt.I.get<XmppService>().connect(ConnectionSettings(
          jid: JID.fromString(data["jid"]!),
          password: data["password"]!,
          useDirectTLS: data["useDirectTLS"]!,
          allowPlainAuth: data["allowPlainAuth"]
      ), true);
    }
    break;
    case "LoadMessagesForJidAction": {
      GetIt.I.get<DatabaseService>().loadMessagesForJid(data["jid"]);
    }
    break;
    case "SetCurrentlyOpenChatAction": {
      GetIt.I.get<XmppService>().setCurrentlyOpenedChatJid(data["jid"]);
    }
    break;
    case "AddToRosterAction": {
      final String jid = data["jid"];
      (() async {
          final roster = GetIt.I.get<RosterService>();
          if (await roster.isInRoster(jid)) {
            // TODO: Use a global middleware
            FlutterBackgroundService().sendData(
              AddToRosterResultEvent(
                result: "error",
                msg: "Already in contact list"
              ).toJson()
            );
            return;
          }

          final db = GetIt.I.get<DatabaseService>();
          final conversation = await db.getConversationByJid(jid);
          if (conversation != null) {
            final c = await db.updateConversation(id: conversation.id, open: true);
            FlutterBackgroundService().sendData(
              AddToRosterResultEvent(
                result: "error",
                msg: "Already in contact list"
              ).toJson()
            );

            FlutterBackgroundService().sendData(
              ConversationUpdatedEvent(conversation: c).toJson()
            );
          } else {
            final c = await db.addConversationFromData(
              jid.split("@")[0],
              "",
              "",
              jid,
              0,
              -1,
              [],
              true
            );
            FlutterBackgroundService().sendData(
              ConversationCreatedEvent(conversation: c).toJson()
            );
          }

          roster.addToRosterWrapper("", jid, jid.split("@")[0]);
          FlutterBackgroundService().sendData(
            AddToRosterResultEvent(
              result: "success",
              jid: jid
            ).toJson()
          );
      })();
    }
    break;
    case "RemoveRosterItemAction": {
      (() async {
          final jid = data["jid"]!;
          //await GetIt.I.get<DatabaseService>().removeRosterItemByJid(jid, nullOkay: true);
          await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.removeFromRoster(jid);
          await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.sendUnsubscriptionRequest(jid);
      })();
    }
    break;
    case "SendMessageAction": {
      GetIt.I.get<XmppService>().sendMessage(body: data["body"]!, jid: data["jid"]!);
    }
    break;
    case "SetCSIState": {
      final csi = GetIt.I.get<XmppConnection>().getManagerById(csiManager);
      if (csi == null) {
        return;
      }

      if (data["state"] == "foreground") {
        csi.setActive();
      } else {
        csi.setInactive();
      }
    }
    break;
    case "PerformPrestartAction": {
      // TODO: This assumes that we are ready if we receive this event
      performPreStart((event) {
          // TODO: Maybe register the middleware via GetIt
          final data = event.toJson();
          GetIt.I.get<Logger>().fine("S2F: " + data.toString());

          FlutterBackgroundService().sendData(data);
      });
    }
    break;
    case "DebugSetEnabledAction": {
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugEnabled: data["enabled"] as bool
          ));
          initUDPLogger();
      })();
    }
    break;
    case "DebugSetIpAction": {
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugIp: data["ip"] as String
          ));
          initUDPLogger();
      })();
    }
    break;
    case "DebugSetPortAction": {
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugPort: data["port"] as int
          ));
          initUDPLogger();
      })();
    }
    break;
    case "DebugSetPassphraseAction": {
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugPassphrase: data["passphrase"] as String
          ));
          initUDPLogger();
      })();
    }
    break;
    case "__STOP__": {
      FlutterBackgroundService().stopBackgroundService();
    }
    break;
  }
}
