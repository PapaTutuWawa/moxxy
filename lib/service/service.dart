import "dart:async";

import "package:moxxyv2/shared/logging.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0054.dart";
import "package:moxxyv2/xmpp/xeps/xep_0280.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";
import "package:moxxyv2/xmpp/xeps/xep_0060.dart";
import "package:moxxyv2/xmpp/xeps/xep_0084.dart";
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

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";

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
  final preferences = await GetIt.I.get<PreferencesService>().getPreferences();


  GetIt.I.get<Logger>().finest("account != null: " + (account != null).toString());
  GetIt.I.get<Logger>().finest("settings != null: " + (settings != null).toString());

  if (account!= null && settings != null) {
    await GetIt.I.get<RosterService>().loadRosterFromDatabase();

    // Check some permissions
    final storagePerm = await Permission.storage.status;
    final List<int> permissions = List.empty(growable: true);
    if (storagePerm.isDenied /*&& !state.askedStoragePermission*/) {
      permissions.add(Permission.storage.value);

      await xmpp.modifyXmppState((state) => state.copyWith(
          askedStoragePermission: true
      ));
    }

    sendData(PreStartResultEvent(
        state: "logged_in",
        jid: account.jid,
        displayName: account.displayName,
        avatarUrl: account.avatarUrl,
        debugEnabled: state.debugEnabled,
        permissionsToRequest: permissions,
        preferences: preferences
    ));
  } else {
    sendData(PreStartResultEvent(
        state: "not_logged_in",
        debugEnabled: state.debugEnabled,
        permissionsToRequest: List<int>.empty(),
        preferences: preferences
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

  GetIt.I.registerSingleton<PreferencesService>(PreferencesService());
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
      GetIt.I.registerSingleton<AvatarService>(AvatarService(middleware));

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
      connection.registerManager(CarbonsManager());
      connection.registerManager(PubSubManager());
      connection.registerManager(vCardManager());
      connection.registerManager(UserAvatarManager());
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
    case loadConversationsType: {
      GetIt.I.get<DatabaseService>().loadConversations();
    }
    break;
    case performLoginType: {
      final command = PerformLoginAction.fromJson(data);
      GetIt.I.get<Logger>().fine("Performing login");
      GetIt.I.get<XmppService>().connect(ConnectionSettings(
          jid: JID.fromString(command.jid),
          password: command.password,
          useDirectTLS: command.useDirectTLS,
          allowPlainAuth: command.allowPlainAuth
      ), true);
    }
    break;
    case loadMessagesForJidActionType: {
      final command = LoadMessagesForJidAction.fromJson(data);
      GetIt.I.get<DatabaseService>().loadMessagesForJid(command.jid);
    }
    break;
    case setCurrentlyOpenChatType: {
      final command = SetCurrentlyOpenChatAction.fromJson(data);
      GetIt.I.get<XmppService>().setCurrentlyOpenedChatJid(command.jid);
    }
    break;
    case addToRosterType: {
      final command = AddToRosterAction.fromJson(data);
      final String jid = command.jid;
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

          roster.addToRosterWrapper("", jid, jid.split("@")[0]);
          FlutterBackgroundService().sendData(
            AddToRosterResultEvent(
              result: "success",
              jid: jid
            ).toJson()
          );

          final db = GetIt.I.get<DatabaseService>();
          final conversation = await db.getConversationByJid(jid);
          if (conversation != null) {
            final c = await db.updateConversation(id: conversation.id, open: true);

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
          
          // Try to figure out an avatar
          await GetIt.I.get<AvatarService>().subscribeJid(jid);
          GetIt.I.get<AvatarService>().fetchAndUpdateAvatarForJid(jid);
      })();
    }
    break;
    case removeRosterItemActionType: {
      final command = RemoveRosterItemAction.fromJson(data);
      GetIt.I.get<RosterService>().removeFromRosterWrapper(command.jid);
      GetIt.I.get<AvatarService>().unsubscribeJid(command.jid.toString());
    }
    break;
    case sendMessageActionType: {
      final command = SendMessageAction.fromJson(data);
      GetIt.I.get<XmppService>().sendMessage(
        body: command.body,
        jid: command.jid,
        quotedMessage: command.quotedMessage
      );
    }
    break;
    case setCSIStateType: {
      final command = SetCSIStateAction.fromJson(data);
      final csi = GetIt.I.get<XmppConnection>().getManagerById(csiManager);
      if (csi == null) {
        return;
      }

      if (command.state == "foreground") {
        csi.setActive();
      } else {
        csi.setInactive();
      }
    }
    break;
    case performPrestartActionType: {
      // TODO: This assumes that we are ready if we receive this event
      performPreStart((event) {
          // TODO: Maybe register the middleware via GetIt
          final data = event.toJson();
          GetIt.I.get<Logger>().fine("S2F: " + data.toString());

          FlutterBackgroundService().sendData(data);
      });
    }
    break;
    case debugSetEnabledActionType: {
      final command = DebugSetEnabledAction.fromJson(data);
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugEnabled: command.enabled
          ));
          initUDPLogger();
      })();
    }
    break;
    case debugSetIpActionType: {
      final command = DebugSetIpAction.fromJson(data);
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugIp: command.ip
          ));
          initUDPLogger();
      })();
    }
    break;
    case debugSetPortActionType: {
      final command = DebugSetPortAction.fromJson(data);
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugPort: command.port
          ));
          initUDPLogger();
      })();
    }
    break;
    case debugSetPassphraseActionType: {
      final command = DebugSetPassphraseAction.fromJson(data);
      (() async {
          await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
              debugPassphrase: command.passphrase
          ));
          initUDPLogger();
      })();
    }
    break;
    case performDownloadActionType: {
      final command = PerformDownloadAction.fromJson(data);
      sendDataMiddleware(FlutterBackgroundService())(
        MessageUpdatedEvent(message: command.message.copyWith(isDownloading: true))
      );

      (() async {
          final download = GetIt.I.get<DownloadService>();
          final metadata = await download.peekFile(command.message.srcUrl!);

          // TODO: Maybe deduplicate with the code in the xmpp service
          // NOTE: This either works by returing "jpg" for ".../hallo.jpg" or fails
          //       for ".../aaaaaaaaa", in which case we would've failed anyways.
          final ext = command.message.srcUrl!.split(".").last;
          final mimeGuess = metadata.mime ?? guessMimeTypeFromExtension(ext);
          
          await download.downloadFile(command.message.srcUrl!, command.message.id, command.message.conversationJid, mimeGuess);
      })();
    }
    break;
    case setPreferencesCommandType: {
      final command = SetPreferencesCommand.fromJson(data);

      GetIt.I.get<PreferencesService>().modifyPreferences((prefs) => command.preferences);
    }
    break;
    case stopActionType: {
      FlutterBackgroundService().stopBackgroundService();
    }
    break;
  }
}
