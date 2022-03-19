import "package:moxxyv2/ui/handler.dart";
import "package:moxxyv2/ui/constants.dart";
/*
import "package:moxxyv2/ui/pages/conversation/conversation.dart";
import "package:moxxyv2/ui/pages/conversations.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/ui/pages/newconversation.dart";
import "package:moxxyv2/ui/pages/register/register.dart";
import "package:moxxyv2/ui/pages/addcontact/addcontact.dart";
import "package:moxxyv2/ui/pages/postregister/postregister.dart";
import "package:moxxyv2/ui/pages/sendfiles.dart";
import "package:moxxyv2/ui/pages/blocklist/blocklist.dart";
import "package:moxxyv2/ui/pages/settings/settings.dart";
import "package:moxxyv2/ui/pages/settings/licenses.dart";
import "package:moxxyv2/ui/pages/settings/about.dart";
import "package:moxxyv2/ui/pages/settings/debugging.dart";
import "package:moxxyv2/ui/pages/settings/privacy.dart";
import "package:moxxyv2/ui/pages/settings/network.dart";
import "package:moxxyv2/ui/pages/settings/appearance.dart";
import "package:moxxyv2/ui/redux/conversations/middlewares.dart";
import "package:moxxyv2/ui/redux/account/middlewares.dart";
import "package:moxxyv2/ui/redux/login/middlewares.dart";
import "package:moxxyv2/ui/redux/registration/middlewares.dart";
import "package:moxxyv2/ui/redux/addcontact/middlewares.dart";
import "package:moxxyv2/ui/redux/roster/middlewares.dart";
import "package:moxxyv2/ui/redux/messages/middleware.dart";
import "package:moxxyv2/ui/redux/conversation/middlewares.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/start/middlewares.dart";
import "package:moxxyv2/ui/redux/debug/middlewares.dart";
import "package:moxxyv2/ui/redux/preferences/middlewares.dart";
import "package:moxxyv2/ui/redux/blocklist/middlewares.dart";
*/
import "package:moxxyv2/ui/pages/login/login.dart";
import "package:moxxyv2/ui/pages/intro.dart";
import "package:moxxyv2/ui/pages/splashscreen/splashscreen.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";
import "package:moxxyv2/ui/bloc/login_bloc.dart";
import "package:moxxyv2/ui/service/download.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/shared/commands.dart" as commands;

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flow_builder/flow_builder.dart";
import "package:flutter_bloc/flutter_bloc.dart";
/*
import "package:flutter_redux/flutter_redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:redux_logging/redux_logging.dart";
import "package:redux/redux.dart";
*/
import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

// TODO: Replace all Column(children: [ Padding(), Padding, ...]) with a
//       Padding(padding: ..., child: Column(children: [ ... ]))
// TODO: Theme the switches
// TODO: Find a better way to do this
void main() async {
  GetIt.I.registerSingleton<UIDownloadService>(UIDownloadService());

  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print("[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}");
  });
  GetIt.I.registerSingleton<Logger>(Logger("MoxxyMain"));

  // TODO: Uncomment all FlutterBackgroundService things
  //await initializeServiceIfNeeded();
  //FlutterBackgroundService().onDataReceived.listen(handleBackgroundServiceData);
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NavigationBloc>(
          create: (_) => NavigationBloc() 
        ),
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc()
        )
      ],
      child: MyApp()
    )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  _MyAppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    /*FlutterBackgroundService().sendData(
      commands.PerformPrestartAction().toJson()
    );*/
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        /*FlutterBackgroundService().sendData(
          commands.SetCSIStateAction(state: "background").toJson()
        );*/
        break;
      case AppLifecycleState.resumed:
        /*FlutterBackgroundService().sendData(
          commands.SetCSIStateAction(state: "foreground").toJson()
        );*/
        break;
      default: break;
    }
  }

  List<Page> _onGeneratePages(NavigationStatus status, List<Page> pages) {
    switch (status) {
      case NavigationStatus.splashscreen: return [
        Splashscreen.page()
      ];
      case NavigationStatus.intro: return [
        Intro.page()
      ];
      case NavigationStatus.login: return [
        Intro.page(),
        Login.page()
      ];
    }

    return [];
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
      //navigatorKey: NavigatorHolder.navigatorKey,
      themeMode: ThemeMode.system,
      /*
      routes: {
        introRoute: (context) => const IntroPage(),
        loginRoute: (context) => LoginPage(),
        registrationRoute: (context) => RegistrationPage(),
        postRegistrationRoute: (context) => const PostRegistrationPage(),
        conversationsRoute: (context) => const ConversationsPage(),
        conversationRoute: (context) => const ConversationPage(),
        profileRoute: (context) => const ProfilePage(),
        sendFilesRoute: (context) => SendFilesPage(),
        newConversationRoute: (context) => const NewConversationPage(),
        addContactRoute: (context) => AddContactPage(),
        settingsRoute: (context) => const SettingsPage(),
        licensesRoute: (context) => const SettingsLicensesPage(),
        aboutRoute: (context) => const SettingsAboutPage(),
        debuggingRoute: (context) => DebuggingPage(),
        privacyRoute: (context) => const PrivacyPage(),
        networkRoute: (context) => const NetworkPage(),
        appearanceRoute: (context) => const AppearancePage(),
        blocklistRoute: (context) => BlocklistPage()
      },
      home: const SplashScreen(),
      */
      home: FlowBuilder<NavigationStatus>(
        state: context.watch<NavigationBloc>().state.status,
        onGeneratePages: _onGeneratePages
      )
    );
  }
}
