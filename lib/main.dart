import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/synchronized_queue.dart';
import 'package:moxxyv2/ui/bloc/addcontact_bloc.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/login_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/own_devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/bloc/sharedmedia_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/events.dart';
/*
import "package:moxxyv2/ui/pages/register/register.dart";
import "package:moxxyv2/ui/pages/postregister/postregister.dart";
*/
import 'package:moxxyv2/ui/pages/addcontact.dart';
import 'package:moxxyv2/ui/pages/blocklist.dart';
import 'package:moxxyv2/ui/pages/conversation/conversation.dart';
import 'package:moxxyv2/ui/pages/conversations.dart';
import 'package:moxxyv2/ui/pages/crop.dart';
import 'package:moxxyv2/ui/pages/intro.dart';
import 'package:moxxyv2/ui/pages/login.dart';
import 'package:moxxyv2/ui/pages/newconversation.dart';
import 'package:moxxyv2/ui/pages/profile/devices.dart';
import 'package:moxxyv2/ui/pages/profile/own_devices.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/pages/sendfiles.dart';
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
import 'package:moxxyv2/ui/pages/settings/stickers.dart';
import 'package:moxxyv2/ui/pages/share_selection.dart';
import 'package:moxxyv2/ui/pages/sharedmedia.dart';
import 'package:moxxyv2/ui/pages/splashscreen/splashscreen.dart';
import 'package:moxxyv2/ui/pages/sticker_pack.dart';
import 'package:moxxyv2/ui/pages/util/qrcode.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/service/progress.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:page_transition/page_transition.dart';
import 'package:share_handler/share_handler.dart';

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}');
  });
  GetIt.I.registerSingleton<Logger>(Logger('MoxxyMain'));
}

Future<void> setupUIServices() async {
  GetIt.I.registerSingleton<UIProgressService>(UIProgressService());
  GetIt.I.registerSingleton<UIDataService>(UIDataService());
}

void setupBlocs(GlobalKey<NavigatorState> navKey) {
  GetIt.I.registerSingleton<NavigationBloc>(NavigationBloc(navigationKey: navKey));
  GetIt.I.registerSingleton<ConversationsBloc>(ConversationsBloc());
  GetIt.I.registerSingleton<NewConversationBloc>(NewConversationBloc());
  GetIt.I.registerSingleton<ConversationBloc>(ConversationBloc());
  GetIt.I.registerSingleton<BlocklistBloc>(BlocklistBloc()); GetIt.I.registerSingleton<ProfileBloc>(ProfileBloc());
  GetIt.I.registerSingleton<PreferencesBloc>(PreferencesBloc());
  GetIt.I.registerSingleton<AddContactBloc>(AddContactBloc());
  GetIt.I.registerSingleton<SharedMediaBloc>(SharedMediaBloc());
  GetIt.I.registerSingleton<CropBloc>(CropBloc());
  GetIt.I.registerSingleton<SendFilesBloc>(SendFilesBloc());
  GetIt.I.registerSingleton<CropBackgroundBloc>(CropBackgroundBloc());
  GetIt.I.registerSingleton<ShareSelectionBloc>(ShareSelectionBloc());
  GetIt.I.registerSingleton<ServerInfoBloc>(ServerInfoBloc());
  GetIt.I.registerSingleton<DevicesBloc>(DevicesBloc());
  GetIt.I.registerSingleton<OwnDevicesBloc>(OwnDevicesBloc());
  GetIt.I.registerSingleton<StickersBloc>(StickersBloc());
  GetIt.I.registerSingleton<StickerPackBloc>(StickerPackBloc());
}

// TODO(Unknown): Replace all Column(children: [ Padding(), Padding, ...]) with a
//                Padding(padding: ..., child: Column(children: [ ... ]))
// TODO(Unknown): Theme the switches
void main() async {
  setupLogging();
  await setupUIServices();

  setupEventHandler();

  final navKey = GlobalKey<NavigatorState>();
  setupBlocs(navKey);

  await initializeServiceIfNeeded();
 
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NavigationBloc>(
          create: (_) => GetIt.I.get<NavigationBloc>(),
        ),
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(),
        ),
        BlocProvider<ConversationsBloc>(
          create: (_) => GetIt.I.get<ConversationsBloc>(),
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
        BlocProvider<AddContactBloc>(
          create: (_) => GetIt.I.get<AddContactBloc>(),
        ),
        BlocProvider<SharedMediaBloc>(
          create: (_) => GetIt.I.get<SharedMediaBloc>(),
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
      ],
      child: TranslationProvider(
        child: MyApp(navKey),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {

  const MyApp(this.navigationKey, { super.key });
  final GlobalKey<NavigatorState> navigationKey;

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  MyAppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _setupSharingHandler();
    
    // Lift the UI block
    GetIt.I.get<SynchronizedQueue<Map<String, dynamic>?>>().removeQueueLock();
  }

  Future<void> _handleSharedMedia(SharedMedia media) async {
    final attachments = media.attachments ?? [];
    GetIt.I.get<ShareSelectionBloc>().add(
      ShareSelectionRequestedEvent(
        attachments.map((a) => a!.path).toList(),
        media.content,
        media.content != null ? ShareSelectionType.text : ShareSelectionType.media,
      ),
    );
  }
  
  Future<void> _setupSharingHandler() async {
    final handler = ShareHandlerPlatform.instance;
    final media = await handler.getInitialSharedMedia();

    // Shared while the app was closed
    if (media != null) {
      if (GetIt.I.get<UIDataService>().isLoggedIn) {
        await _handleSharedMedia(media);
      }

      await handler.resetInitialSharedMedia();
    }

    // Shared while the app is stil running
    handler.sharedMediaStream.listen((SharedMedia media) async {
      if (GetIt.I.get<UIDataService>().isLoggedIn) {
        await _handleSharedMedia(media);
      }

      await handler.resetInitialSharedMedia();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final sender = MoxplatformPlugin.handler.getDataSender();
    switch (state) {
      case AppLifecycleState.paused:
        sender.sendData(
          SetCSIStateCommand(active: false),
        );
        GetIt.I.get<ConversationBloc>().add(AppStateChanged(false));
      break;
      case AppLifecycleState.resumed:
        sender.sendData(
          SetCSIStateCommand(active: true),
        );
        GetIt.I.get<ConversationBloc>().add(AppStateChanged(true));
      break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: LocaleSettings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: 'Moxxy',
      theme: getThemeData(context, Brightness.light),
      darkTheme: getThemeData(context, Brightness.dark),
      navigatorKey: widget.navigationKey,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case introRoute: return Intro.route;
          case loginRoute: return Login.route;
          case conversationsRoute: return ConversationsPage.route;
          case newConversationRoute: return NewConversationPage.route;
          case conversationRoute: return PageTransition<dynamic>(
            type: PageTransitionType.rightToLeft,
            settings: settings,
            child: const ConversationPage(),
          );
          case sharedMediaRoute: return SharedMediaPage.route;
          case blocklistRoute: return BlocklistPage.route;
          case profileRoute: return ProfilePage.route;
          case settingsRoute: return SettingsPage.route;
          case aboutRoute: return SettingsAboutPage.route;
          case licensesRoute: return SettingsLicensesPage.route;
          case networkRoute: return NetworkPage.route;
          case privacyRoute: return PrivacyPage.route;
          case debuggingRoute: return DebuggingPage.route;
          case addContactRoute: return AddContactPage.route;
          case cropRoute: return CropPage.route;
          case sendFilesRoute: return SendFilesPage.route;
          case backgroundCroppingRoute: return CropBackgroundPage.route;
          case shareSelectionRoute: return ShareSelectionPage.route;
          case serverInfoRoute: return ServerInfoPage.route;
          case conversationSettingsRoute: return ConversationSettingsPage.route;
          case devicesRoute: return DevicesPage.route;
          case ownDevicesRoute: return OwnDevicesPage.route;
          case appearanceRoute: return AppearanceSettingsPage.route;
          case qrCodeScannerRoute: return QrCodeScanningPage.getRoute(
            settings.arguments! as QrCodeScanningArguments,
          );
          case stickersRoute: return StickersSettingsPage.route;
          case stickerPackRoute: return StickerPackPage.route;
        }

        return null;
      },
      home: const Splashscreen(),
    );
  }
}
