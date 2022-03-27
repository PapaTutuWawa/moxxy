import "package:moxxyv2/ui/events.dart";
import "package:moxxyv2/ui/constants.dart";
/*
import "package:moxxyv2/ui/pages/register/register.dart";
import "package:moxxyv2/ui/pages/postregister/postregister.dart";
import "package:moxxyv2/ui/pages/sendfiles.dart";
*/
import "package:moxxyv2/ui/pages/addcontact/addcontact.dart";
import "package:moxxyv2/ui/pages/settings/debugging.dart";
import "package:moxxyv2/ui/pages/settings/privacy.dart";
import "package:moxxyv2/ui/pages/settings/network.dart";
import "package:moxxyv2/ui/pages/settings/appearance.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/ui/pages/settings/settings.dart";
import "package:moxxyv2/ui/pages/settings/licenses.dart";
import "package:moxxyv2/ui/pages/settings/about.dart";
import "package:moxxyv2/ui/pages/blocklist.dart";
import "package:moxxyv2/ui/pages/conversation.dart";
import "package:moxxyv2/ui/pages/newconversation.dart";
import "package:moxxyv2/ui/pages/conversations.dart";
import "package:moxxyv2/ui/pages/login/login.dart";
import "package:moxxyv2/ui/pages/intro.dart";
import "package:moxxyv2/ui/pages/splashscreen/splashscreen.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";
import "package:moxxyv2/ui/bloc/login_bloc.dart";
import "package:moxxyv2/ui/bloc/conversations_bloc.dart";
import "package:moxxyv2/ui/bloc/newconversation_bloc.dart";
import "package:moxxyv2/ui/bloc/conversation_bloc.dart";
import "package:moxxyv2/ui/bloc/blocklist_bloc.dart";
import "package:moxxyv2/ui/bloc/profile_bloc.dart";
import "package:moxxyv2/ui/bloc/preferences_bloc.dart";
import "package:moxxyv2/ui/bloc/addcontact_bloc.dart";
import "package:moxxyv2/ui/service/download.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/backgroundsender.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print("[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}");
  });
  GetIt.I.registerSingleton<Logger>(Logger("MoxxyMain"));
}

void setupUIServices() {
  GetIt.I.registerSingleton<UIDownloadService>(UIDownloadService());
}

void setupBlocs(GlobalKey<NavigatorState> navKey) {
  GetIt.I.registerSingleton<NavigationBloc>(NavigationBloc(navigationKey: navKey));
  GetIt.I.registerSingleton<ConversationsBloc>(ConversationsBloc());
  GetIt.I.registerSingleton<NewConversationBloc>(NewConversationBloc());
  GetIt.I.registerSingleton<ConversationBloc>(ConversationBloc());
  GetIt.I.registerSingleton<BlocklistBloc>(BlocklistBloc());
  GetIt.I.registerSingleton<ProfileBloc>(ProfileBloc());
  GetIt.I.registerSingleton<PreferencesBloc>(PreferencesBloc());
  GetIt.I.registerSingleton<AddContactBloc>(AddContactBloc());
}

// TODO: Replace all Column(children: [ Padding(), Padding, ...]) with a
//       Padding(padding: ..., child: Column(children: [ ... ]))
// TODO: Theme the switches
void main() async {
  setupLogging();
  setupUIServices();
  
  await initializeServiceIfNeeded();
  setupEventHandler();
  GetIt.I.registerSingleton<BackgroundServiceDataSender>(BackgroundServiceDataSender());
  
  final navKey = GlobalKey<NavigatorState>();
  setupBlocs(navKey);
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NavigationBloc>(
          create: (_) => GetIt.I.get<NavigationBloc>()
        ),
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc()
        ),
        BlocProvider<ConversationsBloc>(
          create: (_) => GetIt.I.get<ConversationsBloc>()
        ),
        BlocProvider<NewConversationBloc>(
          create: (_) => GetIt.I.get<NewConversationBloc>()
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => GetIt.I.get<ConversationBloc>()
        ),
        BlocProvider<BlocklistBloc>(
          create: (_) => GetIt.I.get<BlocklistBloc>()
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => GetIt.I.get<ProfileBloc>()
        ),
        BlocProvider<PreferencesBloc>(
          create: (_) => GetIt.I.get<PreferencesBloc>()
        ),
        BlocProvider<AddContactBloc>(
          create: (_) => GetIt.I.get<AddContactBloc>()
        )
      ],
      child: MyApp(navKey)
    )
  );
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigationKey;

  const MyApp(this.navigationKey, { Key? key }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState(navigationKey);
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigationKey;

  _MyAppState(this.navigationKey);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _performPreStart();
  }

  Future<void> _performPreStart() async {
    final result = await GetIt.I.get<BackgroundServiceDataSender>().sendData(
      PerformPreStartCommand()
    ) as PreStartDoneEvent;

    GetIt.I.get<PreferencesBloc>().add(
      PreferencesChangedEvent(result.preferences)
    );
    
    if (result.state == preStartLoggedInState) {
      GetIt.I.get<ConversationsBloc>().add(
        ConversationsInitEvent(
          result.displayName!,
          result.jid!,
          result.conversations!
        )
      );
      GetIt.I.get<NewConversationBloc>().add(
        NewConversationInitEvent(
          result.roster!
        )
      );

      navigationKey.currentState!.pushNamedAndRemoveUntil(
        conversationsRoute,
        (_) => false
      );
    } else if (result.state == preStartNotLoggedInState) {
      navigationKey.currentState!.pushNamedAndRemoveUntil(
        introRoute,
        (_) => false
      );
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final sender = GetIt.I.get<BackgroundServiceDataSender>();
    switch (state) {
      case AppLifecycleState.paused: sender.sendData(
          SetCSIStateCommand(active: false)
        );
        break;
      case AppLifecycleState.resumed: sender.sendData(
          SetCSIStateCommand(active: true)
        );
        break;
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Moxxy",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: primaryColor,
            onPrimary: Colors.white
          )
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: primaryColor
          )
        ),
        // NOTE: Mainly for the SettingsSection
        colorScheme: const ColorScheme.dark(
          secondary: primaryColor
        ),

        backgroundColor: const Color(0xff303030)
      ),
      navigatorKey: navigationKey,
      themeMode: ThemeMode.system,
      routes: {
        introRoute: (context) => const Intro(),
        loginRoute: (context) => const Login(),
        conversationsRoute: (context) => const ConversationsPage(),
        newConversationRoute: (context) => const NewConversationPage(),
        conversationRoute: (context) => const ConversationPage(),
        blocklistRoute: (context) => BlocklistPage(),
        profileRoute: (context) => const ProfilePage(),
        settingsRoute: (context) => const SettingsPage(),
        aboutRoute: (context) => const SettingsAboutPage(),
        licensesRoute: (context) => const SettingsLicensesPage(),
        appearanceRoute: (context) => const AppearancePage(),
        networkRoute: (context) => const NetworkPage(),
        privacyRoute: (context) => const PrivacyPage(),
        debuggingRoute: (context) => DebuggingPage(),
        addContactRoute: (context) => AddContactPage(),
        /*
        registrationRoute: (context) => RegistrationPage(),
        postRegistrationRoute: (context) => const PostRegistrationPage(),
        sendFilesRoute: (context) => SendFilesPage(),
        */
      },
      home: Splashscreen()
    );
  }
}
