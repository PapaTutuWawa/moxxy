import 'package:flutter/material.dart';
import 'ui/pages/conversation.dart';
import 'ui/pages/conversations.dart';
import 'ui/pages/profile.dart';
import 'ui/pages/newconversation.dart';
import 'ui/pages/login.dart';
import 'ui/pages/register.dart';
import 'ui/pages/intro.dart';
import 'ui/pages/addcontact.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moxxy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark
      ),
      themeMode: ThemeMode.system,
      routes: {
        "/intro": (context) => IntroPage(),
        "/login": (context) => LoginPage(),
        "/register": (context) => RegistrationPage(),
        "/conversations": (context) => ConversationsPage(),
        "/conversation": (context) => ConversationPage(),
        "/conversation/profile": (context) => ProfilePage(),
        "/new_conversation": (context) => NewConversationPage(),
        "/new_conversation/add_contact": (context) => AddContactPage(),
      },
      home: IntroPage(),
    );
  }
}
