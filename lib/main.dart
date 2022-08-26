import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/ui/bloc/addcontact_bloc.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/login_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/bloc/sharedmedia_bloc.dart';
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
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/pages/sendfiles.dart';
import 'package:moxxyv2/ui/pages/settings/about.dart';
import 'package:moxxyv2/ui/pages/settings/appearance/appearance.dart';
import 'package:moxxyv2/ui/pages/settings/appearance/cropbackground.dart';
import 'package:moxxyv2/ui/pages/settings/debugging.dart';
import 'package:moxxyv2/ui/pages/settings/licenses.dart';
import 'package:moxxyv2/ui/pages/settings/network.dart';
import 'package:moxxyv2/ui/pages/settings/privacy/privacy.dart';
import 'package:moxxyv2/ui/pages/settings/settings.dart';
import 'package:moxxyv2/ui/pages/sharedmedia.dart';
import 'package:moxxyv2/ui/pages/splashscreen/splashscreen.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/service/progress.dart';
import 'package:moxxyv2/ui/service/thumbnail.dart';
import 'package:page_transition/page_transition.dart';

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}');
  });
  GetIt.I.registerSingleton<Logger>(Logger('MoxxyMain'));
}

Future<void> setupUIServices() async {
  GetIt.I.registerSingleton<UIProgressService>(UIProgressService());
  GetIt.I.registerSingleton<UIDataService>(UIDataService());
  GetIt.I.registerSingleton<ThumbnailCacheService>(ThumbnailCacheService());
  await GetIt.I.get<UIDataService>().init();}

void setupBlocs(GlobalKey<NavigatorState> navKey) {
  GetIt.I.registerSingleton<NavigationBloc>(NavigationBloc(navigationKey: navKey));
  GetIt.I.registerSingleton<ConversationsBloc>(ConversationsBloc());
  GetIt.I.registerSingleton<NewConversationBloc>(NewConversationBloc());
  GetIt.I.registerSingleton<ConversationBloc>(ConversationBloc());
  GetIt.I.registerSingleton<BlocklistBloc>(BlocklistBloc());
  GetIt.I.registerSingleton<ProfileBloc>(ProfileBloc());
  GetIt.I.registerSingleton<PreferencesBloc>(PreferencesBloc());
  GetIt.I.registerSingleton<AddContactBloc>(AddContactBloc());
  GetIt.I.registerSingleton<SharedMediaBloc>(SharedMediaBloc());
  GetIt.I.registerSingleton<CropBloc>(CropBloc());
  GetIt.I.registerSingleton<SendFilesBloc>(SendFilesBloc());
  GetIt.I.registerSingleton<CropBackgroundBloc>(CropBackgroundBloc());
}

// TODO(Unknown): Replace all Column(children: [ Padding(), Padding, ...]) with a
//                Padding(padding: ..., child: Column(children: [ ... ]))
// TODO(Unknown): Theme the switches
void main() async {
  GetIt.I.registerSingleton<Completer<void>>(Completer());

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
        )
      ],
      child: MyApp(navKey),
    ),
  );
}

class MyApp extends StatefulWidget {

  const MyApp(this.navigationKey, { Key? key }) : super(key: key);
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

    // Lift the UI block
    GetIt.I.get<Completer<void>>().complete();
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
      title: 'Moxxy',
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: primaryColor,
            onPrimary: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: primaryColor,
          ),
        ),
        // NOTE: Mainly for the SettingsSection
        colorScheme: const ColorScheme.light(
          secondary: primaryColor,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: primaryColor,
            onPrimary: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: primaryColor,
          ),
        ),
        // NOTE: Mainly for the SettingsSection
        colorScheme: const ColorScheme.dark(
          secondary: primaryColor,
        ),

        backgroundColor: const Color(0xff303030),
      ),
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
          case appearanceRoute: return AppearancePage.route;
          case networkRoute: return NetworkPage.route;
          case privacyRoute: return PrivacyPage.route;
          case debuggingRoute: return DebuggingPage.route;
          case addContactRoute: return AddContactPage.route;
          case cropRoute: return CropPage.route;
          case sendFilesRoute: return SendFilesPage.route;
          case backgroundCroppingRoute: return CropBackgroundPage.route;
        }

        return null;
      },
      home: const Splashscreen(),
    );
  }
}
