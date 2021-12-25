import 'package:flutter/material.dart';
import 'ui/pages/conversation/conversation.dart';
import 'ui/pages/conversations.dart';
import 'ui/pages/profile.dart';
import 'ui/pages/newconversation.dart';
import 'ui/pages/login/login.dart';
import 'ui/pages/register/register.dart';
import 'ui/pages/intro.dart';
import 'ui/pages/addcontact/addcontact.dart';
import 'ui/pages/postregister.dart';
import 'ui/pages/settings/settings.dart';
import 'ui/pages/settings/licenses.dart';
import 'ui/pages/settings/about.dart';
import 'repositories/roster.dart';
import 'repositories/roster.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import "redux/conversation/reducers.dart";
import "redux/conversation/actions.dart";
import "redux/state.dart";
import 'package:get_it/get_it.dart';

// TODO: Replace all single quotes with double quotes
// TODO: Replace all Column(children: [ Padding(), Padding, ...]) with a
//       Padding(padding: ..., child: Column(children: [ ... ]))

void main() {
  GetIt.I.registerSingleton<RosterRepository>(RosterRepository());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Store<MoxxyState> store = Store(moxxyReducer,
      initialState: MoxxyState.initialState());

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: this.store,
      child: MaterialApp(
        title: 'Moxxy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark
        ),
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
          "/new_conversation": (context) => NewConversationPage(),
          "/new_conversation/add_contact": (context) => AddContactPage(),
          "/settings": (context) => SettingsPage(),
          "/settings/licenses": (context) => SettingsLicensesPage(),
          "/settings/about": (context) => SettingsAboutPage(),
        },
        home: IntroPage(),
      )
    );
  }
}
