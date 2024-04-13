import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/synchronized_queue.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/events.dart';
/*
import "package:moxxyv2/ui/pages/register/register.dart";
import "package:moxxyv2/ui/pages/postregister/postregister.dart";
*/
import 'package:moxxyv2/ui/pages/blocklist.dart';
import 'package:moxxyv2/ui/pages/conversation/conversation.dart';
import 'package:moxxyv2/ui/pages/crop.dart';
import 'package:moxxyv2/ui/pages/home/home.dart';
import 'package:moxxyv2/ui/pages/intro.dart';
import 'package:moxxyv2/ui/pages/login.dart';
import 'package:moxxyv2/ui/pages/newconversation.dart';
import 'package:moxxyv2/ui/pages/profile/devices.dart';
import 'package:moxxyv2/ui/pages/profile/own_devices.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/pages/sendfiles/sendfiles.dart';
import 'package:moxxyv2/ui/pages/server_info.dart';
import 'package:moxxyv2/ui/pages/settings/about.dart';
import 'package:moxxyv2/ui/pages/settings/appearance/appearance.dart';
import 'package:moxxyv2/ui/pages/settings/appearance/cropbackground.dart';
import 'package:moxxyv2/ui/pages/settings/conversation.dart';
import 'package:moxxyv2/ui/pages/settings/debugging.dart';
import 'package:moxxyv2/ui/pages/settings/licenses.dart';
import 'package:moxxyv2/ui/pages/settings/network.dart';
import 'package:moxxyv2/ui/pages/settings/privacy/privacy.dart';
import 'package:moxxyv2/ui/pages/settings/settings.dart';
import 'package:moxxyv2/ui/pages/settings/sticker_packs.dart';
import 'package:moxxyv2/ui/pages/settings/stickers.dart';
import 'package:moxxyv2/ui/pages/settings/storage/shared_media.dart';
import 'package:moxxyv2/ui/pages/settings/storage/storage.dart';
import 'package:moxxyv2/ui/pages/share_selection.dart';
//import 'package:moxxyv2/ui/pages/sharedmedia.dart';
import 'package:moxxyv2/ui/pages/splashscreen/splashscreen.dart';
import 'package:moxxyv2/ui/pages/startchat.dart';
import 'package:moxxyv2/ui/pages/startgroupchat.dart';
import 'package:moxxyv2/ui/pages/sticker_pack.dart';
import 'package:moxxyv2/ui/pages/util/qrcode.dart';
import 'package:moxxyv2/ui/service/avatars.dart';
import 'package:moxxyv2/ui/service/connectivity.dart';
import 'package:moxxyv2/ui/service/progress.dart';
import 'package:moxxyv2/ui/service/read.dart';
import 'package:moxxyv2/ui/service/sharing.dart';
import 'package:moxxyv2/ui/state/account.dart';
import 'package:moxxyv2/ui/state/blocklist.dart';
import 'package:moxxyv2/ui/state/conversation.dart';
import 'package:moxxyv2/ui/state/conversations.dart';
import 'package:moxxyv2/ui/state/crop.dart';
import 'package:moxxyv2/ui/state/cropbackground.dart';
import 'package:moxxyv2/ui/state/devices.dart';
import 'package:moxxyv2/ui/state/groupchat/joingroupchat.dart';
import 'package:moxxyv2/ui/state/login.dart';
import 'package:moxxyv2/ui/state/navigation.dart';
import 'package:moxxyv2/ui/state/newconversation.dart';
import 'package:moxxyv2/ui/state/own_devices.dart';
import 'package:moxxyv2/ui/state/preferences.dart';
import 'package:moxxyv2/ui/state/profile.dart';
import 'package:moxxyv2/ui/state/request.dart';
import 'package:moxxyv2/ui/state/sendfiles.dart';
import 'package:moxxyv2/ui/state/server_info.dart';
import 'package:moxxyv2/ui/state/share_selection.dart';
import 'package:moxxyv2/ui/state/startchat.dart';
import 'package:moxxyv2/ui/state/sticker_pack.dart';
import 'package:moxxyv2/ui/state/stickers.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:page_transition/page_transition.dart';

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}',
    );
  });
  GetIt.I.registerSingleton<Logger>(Logger('MoxxyMain'));
}

Future<void> setupUIServices() async {
  GetIt.I.registerSingleton<UIProgressService>(UIProgressService());
  GetIt.I.registerSingleton<UIAvatarsService>(UIAvatarsService());
  GetIt.I.registerSingleton<UISharingService>(UISharingService());
  GetIt.I.registerSingleton<UIConnectivityService>(UIConnectivityService());
  GetIt.I.registerSingleton<UIReadMarkerService>(UIReadMarkerService());

  /// Initialize services
  await GetIt.I.get<UIConnectivityService>().initialize();
}

void setupBlocs(GlobalKey<NavigatorState> navKey) {
  GetIt.I.registerSingleton<Navigation>(
    Navigation(navigationKey: navKey),
  );
  GetIt.I.registerSingleton<NewConversationCubit>(NewConversationCubit());
  GetIt.I.registerSingleton<ConversationCubit>(ConversationCubit());
  GetIt.I.registerSingleton<BlocklistCubit>(BlocklistCubit());
  GetIt.I.registerSingleton<ProfileCubit>(ProfileCubit());
  GetIt.I.registerSingleton<PreferencesCubit>(PreferencesCubit());
  GetIt.I.registerSingleton<StartChatCubit>(StartChatCubit());
  GetIt.I.registerSingleton<CropCubit>(CropCubit());
  GetIt.I.registerSingleton<SendFilesCubit>(SendFilesCubit());
  GetIt.I.registerSingleton<CropBackgroundCubit>(CropBackgroundCubit());
  GetIt.I.registerSingleton<ShareSelectionCubit>(ShareSelectionCubit());
  GetIt.I.registerSingleton<ServerInfoCubit>(ServerInfoCubit());
  GetIt.I.registerSingleton<DevicesCubit>(DevicesCubit());
  GetIt.I.registerSingleton<OwnDevicesCubit>(OwnDevicesCubit());
  GetIt.I.registerSingleton<StickersCubit>(StickersCubit());
  GetIt.I.registerSingleton<StickerPackCubit>(StickerPackCubit());
  GetIt.I.registerSingleton<RequestCubit>(RequestCubit());
  GetIt.I.registerSingleton<JoinGroupchatCubit>(JoinGroupchatCubit());
  GetIt.I.registerSingleton<ConversationsCubit>(ConversationsCubit());
  GetIt.I.registerSingleton<AccountCubit>(AccountCubit());
}

void main() async {
  setupLogging();
  await setupUIServices();

  setupEventHandler();

  final navKey = GlobalKey<NavigatorState>();
  setupBlocs(navKey);

  await initializeServiceIfNeeded();

  imageCache.maximumSizeBytes = 500 * 1024 * 1024;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<LoginCubit>(
          create: (_) => LoginCubit(),
        ),
        BlocProvider<ConversationsCubit>(
          create: (_) => GetIt.I.get<ConversationsCubit>(),
        ),
        BlocProvider<NewConversationCubit>(
          create: (_) => GetIt.I.get<NewConversationCubit>(),
        ),
        BlocProvider<ConversationCubit>(
          create: (_) => GetIt.I.get<ConversationCubit>(),
        ),
        BlocProvider<BlocklistCubit>(
          create: (_) => GetIt.I.get<BlocklistCubit>(),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => GetIt.I.get<ProfileCubit>(),
        ),
        BlocProvider<PreferencesCubit>(
          create: (_) => GetIt.I.get<PreferencesCubit>(),
        ),
        BlocProvider<StartChatCubit>(
          create: (_) => GetIt.I.get<StartChatCubit>(),
        ),
        BlocProvider<CropCubit>(
          create: (_) => GetIt.I.get<CropCubit>(),
        ),
        BlocProvider<SendFilesCubit>(
          create: (_) => GetIt.I.get<SendFilesCubit>(),
        ),
        BlocProvider<CropBackgroundCubit>(
          create: (_) => GetIt.I.get<CropBackgroundCubit>(),
        ),
        BlocProvider<ShareSelectionCubit>(
          create: (_) => GetIt.I.get<ShareSelectionCubit>(),
        ),
        BlocProvider<ServerInfoCubit>(
          create: (_) => GetIt.I.get<ServerInfoCubit>(),
        ),
        BlocProvider<DevicesCubit>(
          create: (_) => GetIt.I.get<DevicesCubit>(),
        ),
        BlocProvider<OwnDevicesCubit>(
          create: (_) => GetIt.I.get<OwnDevicesCubit>(),
        ),
        BlocProvider<StickersCubit>(
          create: (_) => GetIt.I.get<StickersCubit>(),
        ),
        BlocProvider<StickerPackCubit>(
          create: (_) => GetIt.I.get<StickerPackCubit>(),
        ),
        BlocProvider<RequestCubit>(
          create: (_) => GetIt.I.get<RequestCubit>(),
        ),
        BlocProvider<JoinGroupchatCubit>(
          create: (_) => GetIt.I.get<JoinGroupchatCubit>(),
        ),
        BlocProvider<AccountCubit>(
          create: (_) => GetIt.I.get<AccountCubit>(),
        ),
      ],
      child: TranslationProvider(
        child: MyApp(navKey),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp(this.navigationKey, {super.key});
  final GlobalKey<NavigatorState> navigationKey;

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  MyAppState();

  @override
  void initState() {
    super.initState();
    _initState();
  }

  /// Async "version" of initState()
  Future<void> _initState() async {
    WidgetsBinding.instance.addObserver(this);

    // Set up receiving share intents
    await GetIt.I.get<UISharingService>().initialize();

    // Lift the UI block
    await GetIt.I
        .get<SynchronizedQueue<Map<String, dynamic>?>>()
        .removeQueueLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final foreground = getForegroundService();
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        foreground.send(
          SetCSIStateCommand(active: false),
        );
        BidirectionalConversationController.currentController
            ?.handleAppStateChange(false);
      case AppLifecycleState.resumed:
        foreground.send(
          SetCSIStateCommand(active: true),
        );
        BidirectionalConversationController.currentController
            ?.handleAppStateChange(true);
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final light = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: primaryColor);
        final dark = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
            );

        return MaterialApp(
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          title: 'Moxxy',
          theme: ThemeData(
            colorScheme: light,
            extensions: [
              getMoxxyThemeData(Brightness.light),
            ],
          ),
          darkTheme: ThemeData(
            colorScheme: dark,
            extensions: [
              getMoxxyThemeData(Brightness.dark),
            ],
          ),
          navigatorKey: widget.navigationKey,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case introRoute:
                return Intro.route;
              case loginRoute:
                return Login.route;
              case homeRoute:
                return ConversationsPage.route;
              case newConversationRoute:
                return NewConversationPage.route;
              case conversationRoute:
                final args = settings.arguments! as ConversationPageArguments;
                return PageTransition<dynamic>(
                  type: PageTransitionType.rightToLeft,
                  settings: settings,
                  child: ConversationPage(
                    conversationJid: args.conversationJid,
                    initialText: args.initialText,
                    conversationType: args.type,
                  ),
                );
              // case sharedMediaRoute:
              //   return SharedMediaPage.getRoute(
              //     settings.arguments! as SharedMediaPageArguments,
              //   );
              case blocklistRoute:
                return BlocklistPage.route;
              case profileRoute:
                return ProfilePage.getRoute(
                  settings.arguments! as ProfileArguments,
                );
              case settingsRoute:
                return PageTransition<dynamic>(
                  type: PageTransitionType.rightToLeft,
                  child: const SettingsPage(),
                );
              case aboutRoute:
                return SettingsAboutPage.route;
              case licensesRoute:
                return SettingsLicensesPage.route;
              case networkRoute:
                return NetworkPage.route;
              case privacyRoute:
                return PrivacyPage.route;
              case debuggingRoute:
                return DebuggingPage.route;
              case addContactRoute:
                return StartChatPage.route;
              case joinGroupchatRoute:
                return JoinGroupchatPage.getRoute(
                  settings.arguments! as JoinGroupchatArguments,
                );
              case cropRoute:
                return CropPage.route;
              case sendFilesRoute:
                return SendFilesPage.route;
              case backgroundCroppingRoute:
                return CropBackgroundPage.route;
              case shareSelectionRoute:
                return ShareSelectionPage.route;
              case serverInfoRoute:
                return ServerInfoPage.route;
              case conversationSettingsRoute:
                return ConversationSettingsPage.route;
              case devicesRoute:
                return DevicesPage.route;
              case ownDevicesRoute:
                return OwnDevicesPage.route;
              case appearanceRoute:
                return AppearanceSettingsPage.route;
              case qrCodeScannerRoute:
                return QrCodeScanningPage.getRoute(
                  settings.arguments! as QrCodeScanningArguments,
                );
              case stickersRoute:
                return StickersSettingsPage.route;
              case stickerPacksRoute:
                return StickerPacksSettingsPage.route;
              case stickerPackRoute:
                return StickerPackPage.route;
              case storageSettingsRoute:
                return StorageSettingsPage.route;
              case storageSharedMediaSettingsRoute:
                return StorageSharedMediaPage.route;
            }

            return null;
          },
          home: const Splashscreen(),
        );
      },
    );
  }
}
