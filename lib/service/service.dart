import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/connectivity_watcher.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/cryptography/cryptography.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/events.dart';
import 'package:moxxyv2/service/files.dart';
import 'package:moxxyv2/service/groupchat.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/language.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/moxxmpp/connectivity.dart';
import 'package:moxxyv2/service/moxxmpp/roster.dart';
import 'package:moxxyv2/service/moxxmpp/socket.dart';
import 'package:moxxyv2/service/moxxmpp/stream.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/permissions.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/reactions.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/share.dart';
import 'package:moxxyv2/service/stickers.dart';
import 'package:moxxyv2/service/storage.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
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
      logger.fine(
        'Since kDebugMode is true, waiting 600ms before sending PreStartCommand',
      );
      sleep(const Duration(milliseconds: 600));
    }

    logger.info('Attaching to service...');
    await handler.attach(ui_events.receiveIsolateEvent);
    logger.info('Done');

    // ignore: cascade_invocations
    logger.info('Service is running. Sending pre start command');
    await handler.getDataSender().sendData(
          PerformPreStartCommand(
            systemLocaleCode: WidgetsBinding.instance.platformDispatcher.locale
                .toLanguageTag(),
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
void sendEvent(BackgroundEvent event, {String? id}) {
  // NOTE: *S*erver to *F*oreground
  GetIt.I.get<Logger>().fine('--> ${event.toJson()["type"]}');
  GetIt.I.get<BackgroundService>().sendEvent(event, id: id);
}

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    final logMessageHeader =
        '[${record.level.name}] (${record.loggerName}) ${record.time}: ';
    var msg = record.message;
    do {
      final tooLong = logMessageHeader.length + msg.length >= 967;
      final line =
          tooLong ? msg.substring(0, 967 - logMessageHeader.length) : msg;

      if (tooLong) {
        msg = msg.substring(967 - logMessageHeader.length - 2);
      } else {
        msg = '';
      }

      final logMessage = logMessageHeader + line;

      if (GetIt.I.isRegistered<UDPLogger>()) {
        final udp = GetIt.I.get<UDPLogger>();
        if (udp.isEnabled()) {
          udp.sendLog(
            logMessage,
            record.time.millisecondsSinceEpoch,
            record.level.name,
          );
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
  GetIt.I.registerSingleton<XmppStateService>(XmppStateService());
  GetIt.I.registerSingleton<DatabaseService>(DatabaseService());
  await GetIt.I.get<DatabaseService>().initialize();

  // Initialize services
  GetIt.I.registerSingleton<ConnectivityWatcherService>(
    ConnectivityWatcherService(),
  );
  GetIt.I.registerSingleton<ConnectivityService>(ConnectivityService());
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
  GetIt.I.registerSingleton<StickersService>(StickersService());
  GetIt.I.registerSingleton<FilesService>(FilesService());
  GetIt.I.registerSingleton<ReactionsService>(ReactionsService());
  GetIt.I.registerSingleton<GroupchatService>(GroupchatService());
  GetIt.I.registerSingleton<StorageService>(StorageService());
  GetIt.I.registerSingleton<ShareService>(ShareService());
  GetIt.I.registerSingleton<PermissionsService>(PermissionsService());
  final xmpp = XmppService();
  GetIt.I.registerSingleton<XmppService>(xmpp);

  await GetIt.I.get<NotificationsService>().initialize();
  await GetIt.I.get<ContactsService>().initialize();
  await GetIt.I.get<ConnectivityService>().initialize();
  await GetIt.I.get<ConnectivityWatcherService>().initialize();

  if (!kDebugMode) {
    final enableDebug =
        (await GetIt.I.get<PreferencesService>().getPreferences()).debugEnabled;
    Logger.root.level = enableDebug ? Level.ALL : Level.INFO;
  }

  // Init the UDPLogger
  await initUDPLogger();

  final connectivityManager = MoxxyConnectivityManager();
  await connectivityManager.initialize();
  final connection = XmppConnection(
    RandomBackoffReconnectionPolicy(1, 6),
    connectivityManager,
    ClientToServerNegotiator(),
    MoxxyTCPSocketWrapper(),
  );
  await connection.registerFeatureNegotiators([
    ResourceBindingNegotiator(),
    StartTlsNegotiator(),
    StreamManagementNegotiator(),
    CSINegotiator(),
    RosterFeatureNegotiator(),
    PresenceNegotiator(),
    SaslScramNegotiator(10, '', '', ScramHashType.sha512),
    SaslScramNegotiator(9, '', '', ScramHashType.sha256),
    SaslScramNegotiator(8, '', '', ScramHashType.sha1),
    SaslPlainNegotiator(),
    Sasl2Negotiator(),
    Bind2Negotiator(),
    FASTSaslNegotiator(),
  ]);
  await connection.registerManagers([
    MoxxyStreamManagementManager(),
    DiscoManager([
      const Identity(category: 'client', type: 'phone', name: 'Moxxy'),
    ]),
    RosterManager(MoxxyRosterStateManager()),
    OmemoManager(
      GetIt.I.get<OmemoService>().getOmemoManager,
      (toJid, _) async =>
          GetIt.I.get<ConversationService>().shouldEncryptForConversation(
                toJid,
                await GetIt.I.get<XmppStateService>().getAccountJid(),
              ),
    ),
    PingManager(const Duration(minutes: 3)),
    MessageManager(),
    PresenceManager(),
    EntityCapabilitiesManager('http://moxxy.im'),
    CSIManager(),
    CarbonsManager(),
    PubSubManager(),
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
    StickersManager(),
    MessageProcessingHintManager(),
    MUCManager(),
    OccupantIdManager(),
  ]);
  GetIt.I.registerSingleton<XmppConnection>(connection);
  GetIt.I.get<Logger>().finest('Done with xmpp');

  // Ensure our data directory exists
  final dir = Directory(
    await MoxplatformPlugin.platform.getPersistentDataPath(),
  );
  if (!dir.existsSync()) {
    GetIt.I
        .get<Logger>()
        .finest('Data dir ${dir.path} does not exist. Creating...');
    await dir.create(recursive: true);
    GetIt.I.get<Logger>().finest('Done');
  }

  // Ensure we can access translations here
  // TODO(Unknown): This does *NOT* allow us to get the system's locale as we have no
  //                window here.
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  final settings = await xmpp.getConnectionSettings();
  GetIt.I.get<Logger>().finest('Got settings');
  if (settings != null) {
    unawaited(
      GetIt.I
          .get<OmemoService>()
          .initializeIfNeeded(settings.jid.toBare().toString()),
    );

    // Potentially set the notification avatar
    await GetIt.I.get<NotificationsService>().maybeSetAvatarFromState();

    // The title of the notification will be changed as soon as the connection state
    // of [XmppConnection] changes.
    await connection
        .getManagerById<MoxxyStreamManagementManager>(smManager)!
        .loadState();
    await xmpp.connect(settings, false);
  } else {
    GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          t.notifications.permanent.idle,
        );
  }

  unawaited(
    GetIt.I.get<SynchronizedQueue<Map<String, dynamic>?>>().removeQueueLock(),
  );
  sendEvent(ServiceReadyEvent());
}

@pragma('vm:entry-point')
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
