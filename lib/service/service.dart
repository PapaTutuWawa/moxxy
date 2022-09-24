import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/awaitabledatasender.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxplatform_platform_interface/moxplatform_platform_interface.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/connectivity_watcher.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/events.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/managers/disco.dart';
import 'package:moxxyv2/service/managers/roster.dart';
import 'package:moxxyv2/service/managers/stream.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/moxxmpp/omemo.dart';
import 'package:moxxyv2/service/moxxmpp/reconnect.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/omemo.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/logging.dart';
import 'package:moxxyv2/ui/events.dart' as ui_events;
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/message.dart';
import 'package:moxxyv2/xmpp/negotiators/resource_binding.dart';
import 'package:moxxyv2/xmpp/negotiators/sasl/plain.dart';
import 'package:moxxyv2/xmpp/negotiators/sasl/scram.dart';
import 'package:moxxyv2/xmpp/negotiators/starttls.dart';
import 'package:moxxyv2/xmpp/ping.dart';
import 'package:moxxyv2/xmpp/presence.dart';
import 'package:moxxyv2/xmpp/roster.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_upload_notification.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0054.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0066.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0084.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0184.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0191.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/negotiator.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0280.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0333.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0352.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0359.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0363.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0380.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0385.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0447.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0461.dart';

Future<void> initializeServiceIfNeeded() async {
  final logger = GetIt.I.get<Logger>();
  final handler = MoxplatformPlugin.handler;
  if (await handler.isRunning()) {
    if (kDebugMode) {
      logger.fine('Since kDebugMode is true, waiting 600ms before sending PreStartCommand');
      sleep(const Duration(milliseconds: 600));
    }

    logger.info('Attaching to service...');
    await handler.attach(ui_events.handleIsolateEvent);
    logger.info('Done');

    // ignore: cascade_invocations
    logger.info('Service is running. Sending pre start command');
    await handler.getDataSender().sendData(
      PerformPreStartCommand(),
      awaitable: false,
    );
  } else {
    logger.info('Service is not running. Initializing service... ');
    await handler.start(
      entrypoint,
      handleUiEvent,
      ui_events.handleIsolateEvent,
    );
  }
}

/// A middleware for packing an event into a [DataWrapper] and also
/// logging what we send.
void sendEvent(BackgroundEvent event, { String? id }) {
  // NOTE: *S*erver to *F*oreground
  GetIt.I.get<Logger>().fine('S2F: ${event.toJson()}');
  GetIt.I.get<BackgroundService>().sendEvent(event, id: id);
}

void setupLogging() {
  //Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.level = Level.ALL;
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
  // Register the lock
  GetIt.I.registerSingleton<Completer<void>>(Completer());

  // Register singletons
  GetIt.I.registerSingleton<Logger>(Logger('MoxxyService'));
  GetIt.I.registerSingleton<UDPLogger>(UDPLogger());

  setupLogging();
  setupBackgroundEventHandler();

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
  final xmpp = XmppService();
  GetIt.I.registerSingleton<XmppService>(xmpp);

  await GetIt.I.get<NotificationsService>().init();
  
  // Init the UDPLogger
  await initUDPLogger();
  
  GetIt.I.registerSingleton<MoxxyReconnectionPolicy>(MoxxyReconnectionPolicy());
  final connection = XmppConnection(GetIt.I.get<MoxxyReconnectionPolicy>())
    ..registerManagers([
      MoxxyStreamManagementManager(),
      MoxxyDiscoManager(),
      MoxxyRosterManager(),
      MoxxyOmemoManager(),
      PingManager(),
      MessageManager(),
      PresenceManager(),
      CSIManager(),
      CarbonsManager(),
      PubSubManager(),
      VCardManager(),
      UserAvatarManager(),
      StableIdManager(),
      SIMSManager(),
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
    ])
    ..registerFeatureNegotiators([
      ResourceBindingNegotiator(),
      StartTlsNegotiator(),
      StreamManagementNegotiator(),
      CSINegotiator(),
      RosterFeatureNegotiator(),
      // TODO(Unknown): This one may not work
      //SaslScramNegotiator(10, '', '', ScramHashType.sha512),
      SaslPlainNegotiator(),
      SaslScramNegotiator(9, '', '', ScramHashType.sha256),
      SaslScramNegotiator(8, '', '', ScramHashType.sha1),
    ]);
    
  GetIt.I.registerSingleton<XmppConnection>(connection);
  GetIt.I.registerSingleton<ConnectivityWatcherService>(ConnectivityWatcherService());
  GetIt.I.registerSingleton<ConnectivityService>(ConnectivityService());
  await GetIt.I.get<ConnectivityService>().initialize();

  GetIt.I.get<Logger>().finest('Done with xmpp');
  
  final settings = await xmpp.getConnectionSettings();

  GetIt.I.get<Logger>().finest('Got settings');
  if (settings != null) {
    await GetIt.I.get<OmemoService>().initialize(settings.jid.toBare().toString());

    // The title of the notification will be changed as soon as the connection state
    // of [XmppConnection] changes.
    await connection.getManagerById<MoxxyStreamManagementManager>(smManager)!.loadState();
    await xmpp.connect(settings, false);
  } else {
    GetIt.I.get<BackgroundService>().setNotification(
      'Moxxy',
      'Idle',
    );
  }

  GetIt.I.get<Logger>().finest('Resolving startup future');
  GetIt.I.get<Completer<void>>().complete();

  sendEvent(ServiceReadyEvent());
}

Future<void> handleUiEvent(Map<String, dynamic>? data) async {
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
