import 'package:flutter/material.dart';
import 'ui/pages/conversation/conversation.dart';
import 'ui/pages/conversations.dart';
import 'ui/pages/profile/profile.dart';
import 'ui/pages/newconversation.dart';
import 'ui/pages/login/login.dart';
import 'ui/pages/register/register.dart';
import 'ui/pages/intro.dart';
import 'ui/pages/addcontact/addcontact.dart';
import 'ui/pages/postregister/postregister.dart';
import 'ui/pages/sendfiles.dart';
import 'ui/pages/settings/settings.dart';
import 'ui/pages/settings/licenses.dart';
import 'ui/pages/settings/about.dart';
import 'ui/constants.dart';
import 'repositories/roster.dart';
import "repositories/conversation.dart";
import "redux/conversation/reducers.dart";
import "redux/conversation/actions.dart";
import "redux/start/actions.dart";
import "redux/conversations/middlewares.dart";
import "redux/account/middlewares.dart";
import "redux/start/middlewares.dart";
import "redux/state.dart";

import 'package:get_it/get_it.dart';
import 'package:flutter_redux/flutter_redux.dart';
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:redux_logging/redux_logging.dart";
import 'package:redux/redux.dart';
import "package:isar/isar.dart";

import "isar.g.dart";

// TODO: Replace all single quotes with double quotes
// TODO: Replace all Column(children: [ Padding(), Padding, ...]) with a
//       Padding(padding: ..., child: Column(children: [ ... ]))
// TODO: Theme the switches
// TODO: Find a better way to do this
void main() async {
  final isar = await openIsar();

  runApp(MyApp(isar: isar));
}

// TODO: Move somewhere else
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/logo.png",
          width: 200, height: 200
        )
      )
    );
  }
}

class MyApp extends StatelessWidget {
  final Store<MoxxyState> store = Store(
    moxxyReducer,
    initialState: MoxxyState.initialState(),
    middleware: [
      conversationsMiddleware,
      startMiddleware,
      accountMiddleware,
      NavigationMiddleware(),
      // TODO: Hide behind a build flavour
      LoggingMiddleware.printer()
    ]
  );
  final Isar isar;

  MyApp({ required this.isar }) {
    GetIt.I.registerSingleton<RosterRepository>(RosterRepository());
    GetIt.I.registerSingleton<DatabaseRepository>(DatabaseRepository(isar: isar, store: this.store));
    GetIt.I.get<DatabaseRepository>().loadConversations();
  }
  
  @override
  Widget build(BuildContext context) {
    this.store.dispatch(PerformPrestartAction());

    return StoreProvider(
      store: this.store,
      child: MaterialApp(
        title: 'Moxxy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              primary: PRIMARY_COLOR,
              onPrimary: Colors.white
            )
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              primary: PRIMARY_COLOR
            )
          ),
          // NOTE: Mainly for the SettingsSection
          colorScheme: ColorScheme.dark(
            secondary: PRIMARY_COLOR
          )
        ),
        navigatorKey: NavigatorHolder.navigatorKey,
        //themeMode: ThemeMode.system,
        themeMode: ThemeMode.dark,
        routes: {
          "/intro": (context) => IntroPage(),
          "/login": (context) => LoginPage(),
          "/register": (context) => RegistrationPage(),
          "/register/post": (context) => PostRegistrationPage(),
          "/conversations": (context) => ConversationsPage(),
          "/conversation": (context) => ConversationPage(),
          "/conversation/profile": (context) => ProfilePage(),
          "/conversation/send_files": (context) => SendFilesPage(),
          "/new_conversation": (context) => NewConversationPage(),
          "/new_conversation/add_contact": (context) => AddContactPage(),
          "/settings": (context) => SettingsPage(),
          "/settings/licenses": (context) => SettingsLicensesPage(),
          "/settings/about": (context) => SettingsAboutPage(),
        },
        home: SplashScreen(),
      )
    );
  }
}
