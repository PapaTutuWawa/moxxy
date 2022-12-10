import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxplatform_platform_interface/moxplatform_platform_interface.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/connectivity_watcher.dart';
import 'package:moxxyv2/service/contact.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/cryptography/cryptography.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/events.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/language.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/moxxmpp/disco.dart';
import 'package:moxxyv2/service/moxxmpp/omemo.dart';
import 'package:moxxyv2/service/moxxmpp/reconnect.dart';
import 'package:moxxyv2/service/moxxmpp/roster.dart';
import 'package:moxxyv2/service/moxxmpp/socket.dart';
import 'package:moxxyv2/service/moxxmpp/stream.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/logging.dart';
import 'package:moxxyv2/shared/synchronized_queue.dart';
import 'package:moxxyv2/ui/events.dart' as ui_events;

Future<void> initializeServiceIfNeeded() async {
  final logger = GetIt.I.get<Logger>();
  final handler = MoxplatformPlugin.handler;
  if (await handler.isRunning()) {
    if (kDebugMode) {
      logger.fine('Since kDebugMode is true, waiting 600ms before sending PreStartCommand');
      sleep(const Duration(milliseconds: 600));
    }

    logger.info('Attaching to service...');
    await handler.attach(ui_events.receiveIsolateEvent);
    logger.info('Done');

    // ignore: cascade_invocations
    logger.info('Service is running. Sending pre start command');
    await handler.getDataSender().sendData(
      PerformPreStartCommand(
        systemLocaleCode: WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
      ),
      awaitable: false,
    );
  } else {
    logger.info('Service is not running. Initializing service... ');
    await handler.start(
      entrypoint,
      receiveUIEvent,
      ui_events.handleIsolateEvent,
    );
  }
}

/// A middleware for packing an event into a [DataWrapper] and also
/// logging what we send.
void sendEvent(BackgroundEvent event, { String? id }) {
  // NOTE: *S*erver to *F*oreground
  GetIt.I.get<Logger>().fine('--> ${event.toJson()["type"]}');
  GetIt.I.get<BackgroundService>().sendEvent(event, id: id);
}

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
      final logMessageHeader = '[${record.level.name}] (${record.loggerName}) ${record.time}: ';
      var msg = record.message;
      do {
        final tooLong = logMessageHeader.length + msg.length >= 967;
        final line = tooLong ? msg.substring(0, 967 - logMessageHeader.length) : msg;

        if (tooLong) {
          msg = msg.substring(967 - logMessageHeader.length - 2);
        } else {
          msg = '';
        }

        final logMessage = logMessageHeader + line;

        if (GetIt.I.isRegistered<UDPLogger>()) {
          final udp = GetIt.I.get<UDPLogger>();
          if (udp.isEnabled()) {
            udp.sendLog(logMessage, record.time.millisecondsSinceEpoch, record.level.name);
          }
        }

        // ignore: literal_only_boolean_expressions
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
    Logger('initUDPLogger').finest('UDPLogger created');

    final port = prefs.debugPort;
    final ip = prefs.debugIp;
    final passphrase = prefs.debugPassphrase;

    if (port != 0 && ip.isNotEmpty && passphrase.isNotEmpty) {
      await GetIt.I.get<UDPLogger>().init(passphrase, ip, port);
    }
  } else {
    GetIt.I.get<UDPLogger>().setEnabled(false);
  }
}

/// The entrypoint for all platforms after the platform specific initilization is done.
@pragma('vm:entry-point')
Future<void> entrypoint() async {
  setupLogging();
  setupBackgroundEventHandler();

  // Register singletons
  GetIt.I.registerSingleton<Logger>(Logger('MoxxyService'));
  GetIt.I.registerSingleton<UDPLogger>(UDPLogger());
  GetIt.I.registerSingleton<LanguageService>(LanguageService());
  
  // Initialize the database
  GetIt.I.registerSingleton<DatabaseService>(DatabaseService());
  await GetIt.I.get<DatabaseService>().initialize();

  GetIt.I.registerSingleton<PreferencesService>(PreferencesService());
  GetIt.I.registerSingleton<BlocklistService>(BlocklistService());
  GetIt.I.registerSingleton<NotificationsService>(NotificationsService());
  GetIt.I.registerSingleton<HttpFileTransferService>(HttpFileTransferService());
  GetIt.I.registerSingleton<AvatarService>(AvatarService());
  GetIt.I.registerSingleton<RosterService>(RosterService());
  GetIt.I.registerSingleton<ConversationService>(ConversationService());
  GetIt.I.registerSingleton<MessageService>(MessageService());
  GetIt.I.registerSingleton<OmemoService>(OmemoService());
  GetIt.I.registerSingleton<CryptographyService>(CryptographyService());
  GetIt.I.registerSingleton<ContactsService>(ContactsService());
  final xmpp = XmppService();
  GetIt.I.registerSingleton<XmppService>(xmpp);

  await GetIt.I.get<NotificationsService>().init();

  if (!kDebugMode) {
    final enableDebug = (await GetIt.I.get<PreferencesService>().getPreferences()).debugEnabled;
    Logger.root.level = enableDebug ? Level.ALL : Level.INFO;
  }
  
  // Init the UDPLogger
  await initUDPLogger();
  
  GetIt.I.registerSingleton<MoxxyReconnectionPolicy>(MoxxyReconnectionPolicy());
  final connection = XmppConnection(
    GetIt.I.get<MoxxyReconnectionPolicy>(),
    MoxxyTCPSocketWrapper(),
  )..registerManagers([
      MoxxyStreamManagementManager(),
      MoxxyDiscoManager(),
      MoxxyRosterManager(),
      MoxxyOmemoManager(),
      PingManager(),
      MessageManager(),
      PresenceManager('http://moxxy.im'),
      CSIManager(),
      CarbonsManager(),
      PubSubManager(),
      VCardManager(),
      UserAvatarManager(),
      StableIdManager(),
      MessageDeliveryReceiptManager(),
      ChatMarkerManager(),
      OOBManager(),
      SFSManager(),
      MessageRepliesManager(),
      BlockingManager(),
      ChatStateManager(),
      HttpFileUploadManager(),
      FileUploadNotificationManager(),
      EmeManager(),
      CryptographicHashManager(),
      DelayedDeliveryManager(),
      MessageRetractionManager(),
      LastMessageCorrectionManager(),
      MessageReactionsManager(),
    ])
    ..registerFeatureNegotiators([
      ResourceBindingNegotiator(),
      StartTlsNegotiator(),
      StreamManagementNegotiator(),
      CSINegotiator(),
      RosterFeatureNegotiator(),
      SaslScramNegotiator(10, '', '', ScramHashType.sha512),
      SaslScramNegotiator(9, '', '', ScramHashType.sha256),
      SaslScramNegotiator(8, '', '', ScramHashType.sha1),
      SaslPlainNegotiator(),
    ]);
    
  GetIt.I.registerSingleton<XmppConnection>(connection);
  GetIt.I.registerSingleton<ConnectivityWatcherService>(ConnectivityWatcherService());
  GetIt.I.registerSingleton<ConnectivityService>(ConnectivityService());
  await GetIt.I.get<ConnectivityService>().initialize();

  GetIt.I.get<Logger>().finest('Done with xmpp');
  
  final settings = await xmpp.getConnectionSettings();

  // Ensure we can access translations here
  // TODO(Unknown): This does *NOT* allow us to get the system's locale as we have no
  //                window here.
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  
  GetIt.I.get<Logger>().finest('Got settings');
  if (settings != null) {
    unawaited(GetIt.I.get<OmemoService>().initializeIfNeeded(settings.jid.toBare().toString()));

    // The title of the notification will be changed as soon as the connection state
    // of [XmppConnection] changes.
    await connection.getManagerById<MoxxyStreamManagementManager>(smManager)!.loadState();
    await xmpp.connect(settings, false);
  } else {
    GetIt.I.get<BackgroundService>().setNotification(
      'Moxxy',
      t.notifications.permanent.idle,
    );
  }

  unawaited(GetIt.I.get<SynchronizedQueue<Map<String, dynamic>?>>().removeQueueLock());
  sendEvent(ServiceReadyEvent());
}

Future<void> receiveUIEvent(Map<String, dynamic>? data) async {
  await GetIt.I.get<SynchronizedQueue<Map<String, dynamic>?>>().add(data);
}

Future<void> handleUIEvent(Map<String, dynamic>? data) async {
  // NOTE: *F*oreground to *S*ervice
  final log = GetIt.I.get<Logger>();

  if (data == null) {
    log.warning('Received null from the UI isolate. Ignoring...');
    return;
  }
  
  final id = data['id']! as String;
  final command = getCommandFromJson(data['data']! as Map<String, dynamic>); 
  if (command == null) {
    log.severe("Unknown command type ${data['type']}");
    return;
  }

  if (command is LoginCommand) {
    final redacted = {
      'id': id,
      'data': LoginCommand(
        jid: command.jid,
        password: '*******',
        useDirectTLS: command.useDirectTLS,
      ).toJson()
    };
    log.fine('F2S: $redacted');
  } else {
    log.fine('F2S: $data');
  }

  unawaited(GetIt.I.get<EventHandler>().run(command, extra: id));
}
