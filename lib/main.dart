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
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/groupchat/joingroupchat_bloc.dart';
import 'package:moxxyv2/ui/bloc/login_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/own_devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/bloc/request_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/bloc/startchat_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/events.dart';
/*
import "package:moxxyv2/ui/pages/register/register.dart";
import "package:moxxyv2/ui/pages/postregister/postregister.dart";
*/
import 'package:moxxyv2/ui/pages/blocklist.dart';
import 'package:moxxyv2/ui/pages/conversation/conversation.dart';
import 'package:moxxyv2/ui/pages/home/home.dart';
import 'package:moxxyv2/ui/pages/crop.dart';
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
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/service/progress.dart';
import 'package:moxxyv2/ui/service/read.dart';
import 'package:moxxyv2/ui/service/sharing.dart';
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
  GetIt.I.registerSingleton<UIDataService>(UIDataService());
  GetIt.I.registerSingleton<UIAvatarsService>(UIAvatarsService());
  GetIt.I.registerSingleton<UISharingService>(UISharingService());
  GetIt.I.registerSingleton<UIConnectivityService>(UIConnectivityService());
  GetIt.I.registerSingleton<UIReadMarkerService>(UIReadMarkerService());

  /// Initialize services
  await GetIt.I.get<UIConnectivityService>().initialize();
}

void setupBlocs(GlobalKey<NavigatorState> navKey) {
  GetIt.I
      .registerSingleton<NavigationBloc>(NavigationBloc(navigationKey: navKey));
  GetIt.I.registerSingleton<NewConversationBloc>(NewConversationBloc());
  GetIt.I.registerSingleton<ConversationBloc>(ConversationBloc());
  GetIt.I.registerSingleton<BlocklistBloc>(BlocklistBloc());
  GetIt.I.registerSingleton<ProfileBloc>(ProfileBloc());
  GetIt.I.registerSingleton<PreferencesBloc>(PreferencesBloc());
  GetIt.I.registerSingleton<StartChatBloc>(StartChatBloc());
  GetIt.I.registerSingleton<CropBloc>(CropBloc());
  GetIt.I.registerSingleton<SendFilesBloc>(SendFilesBloc());
  GetIt.I.registerSingleton<CropBackgroundBloc>(CropBackgroundBloc());
  GetIt.I.registerSingleton<ShareSelectionBloc>(ShareSelectionBloc());
  GetIt.I.registerSingleton<ServerInfoBloc>(ServerInfoBloc());
  GetIt.I.registerSingleton<DevicesBloc>(DevicesBloc());
  GetIt.I.registerSingleton<OwnDevicesBloc>(OwnDevicesBloc());
  GetIt.I.registerSingleton<StickersBloc>(StickersBloc());
  GetIt.I.registerSingleton<StickerPackBloc>(StickerPackBloc());
  GetIt.I.registerSingleton<RequestBloc>(RequestBloc());
  GetIt.I.registerSingleton<JoinGroupchatBloc>(JoinGroupchatBloc());
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
        BlocProvider<NavigationBloc>(
          create: (_) => GetIt.I.get<NavigationBloc>(),
        ),
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(),
        ),
        BlocProvider<ConversationsCubit>(
          create: (_) => GetIt.I.get<ConversationsCubit>(),
        ),
        BlocProvider<NewConversationBloc>(
          create: (_) => GetIt.I.get<NewConversationBloc>(),
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => GetIt.I.get<ConversationBloc>(),
        ),
        BlocProvider<BlocklistBloc>(
          create: (_) => GetIt.I.get<BlocklistBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => GetIt.I.get<ProfileBloc>(),
        ),
        BlocProvider<PreferencesBloc>(
          create: (_) => GetIt.I.get<PreferencesBloc>(),
        ),
        BlocProvider<StartChatBloc>(
          create: (_) => GetIt.I.get<StartChatBloc>(),
        ),
        BlocProvider<CropBloc>(
          create: (_) => GetIt.I.get<CropBloc>(),
        ),
        BlocProvider<SendFilesBloc>(
          create: (_) => GetIt.I.get<SendFilesBloc>(),
        ),
        BlocProvider<CropBackgroundBloc>(
          create: (_) => GetIt.I.get<CropBackgroundBloc>(),
        ),
        BlocProvider<ShareSelectionBloc>(
          create: (_) => GetIt.I.get<ShareSelectionBloc>(),
        ),
        BlocProvider<ServerInfoBloc>(
          create: (_) => GetIt.I.get<ServerInfoBloc>(),
        ),
        BlocProvider<DevicesBloc>(
          create: (_) => GetIt.I.get<DevicesBloc>(),
        ),
        BlocProvider<OwnDevicesBloc>(
          create: (_) => GetIt.I.get<OwnDevicesBloc>(),
        ),
        BlocProvider<StickersBloc>(
          create: (_) => GetIt.I.get<StickersBloc>(),
        ),
        BlocProvider<StickerPackBloc>(
          create: (_) => GetIt.I.get<StickerPackBloc>(),
        ),
        BlocProvider<RequestBloc>(
          create: (_) => GetIt.I.get<RequestBloc>(),
        ),
        BlocProvider<JoinGroupchatBloc>(
          create: (_) => GetIt.I.get<JoinGroupchatBloc>(),
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
          ),
          darkTheme: ThemeData(
            colorScheme: dark,
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
