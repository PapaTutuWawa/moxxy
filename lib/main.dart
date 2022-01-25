import "package:moxxyv2/ui/pages/conversation/conversation.dart";
import "package:moxxyv2/ui/pages/conversations.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/ui/pages/newconversation.dart";
import "package:moxxyv2/ui/pages/login/login.dart";
import "package:moxxyv2/ui/pages/register/register.dart";
import "package:moxxyv2/ui/pages/intro.dart";
import "package:moxxyv2/ui/pages/addcontact/addcontact.dart";
import "package:moxxyv2/ui/pages/postregister/postregister.dart";
import "package:moxxyv2/ui/pages/sendfiles.dart";
import "package:moxxyv2/ui/pages/settings/settings.dart";
import "package:moxxyv2/ui/pages/settings/licenses.dart";
import "package:moxxyv2/ui/pages/settings/about.dart";
import "package:moxxyv2/ui/pages/splashscreen/splashscreen.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";
import "package:moxxyv2/ui/redux/conversations/middlewares.dart";
import "package:moxxyv2/ui/redux/account/middlewares.dart";
import "package:moxxyv2/ui/redux/login/middlewares.dart";
import "package:moxxyv2/ui/redux/login/actions.dart";
import "package:moxxyv2/ui/redux/registration/middlewares.dart";
import "package:moxxyv2/ui/redux/addcontact/middlewares.dart";
import "package:moxxyv2/ui/redux/addcontact/actions.dart";
import "package:moxxyv2/ui/redux/roster/middlewares.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";
import "package:moxxyv2/ui/redux/messages/middleware.dart";
import "package:moxxyv2/ui/redux/conversation/middlewares.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/start/middlewares.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/service/xmpp.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:redux_logging/redux_logging.dart";
import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

Store<MoxxyState> createStore() {
  final store = Store<MoxxyState>(
    moxxyReducer,
    initialState: MoxxyState.initialState(),
    middleware: [
      conversationsMiddleware,
      startMiddleware,
      accountMiddleware,
      loginMiddleware,
      registrationMiddleware,
      addcontactMiddleware,
      rosterMiddleware,
      messageMiddleware,
      conversationMiddleware,
      const NavigationMiddleware(),

      // We only need this while debugging
      ...(kDebugMode ? [ LoggingMiddleware.printer() ] : [])
    ]
  );
  
  return store;
}

// TODO: Replace all Column(children: [ Padding(), Padding, ...]) with a
//       Padding(padding: ..., child: Column(children: [ ... ]))
// TODO: Theme the switches
// TODO: Find a better way to do this
void main() async {
  final store = createStore();

  await initializeServiceIfNeeded();
  
  FlutterBackgroundService().onDataReceived.listen((data) {
      if (data!["type"]! != "__LOG__") {
        // TODO: Use logging function and only print on when debugging
        // ignore: avoid_print
        print("GOT: " + data.toString());
      }

      switch (data["type"]) {
        case "PreStartResult": {
          if (data["state"] == "logged_in") {
            FlutterBackgroundService().sendData({
                "type": "LoadConversationsAction"
            });
            /* TODO: Move this into the XmppRepository
            FlutterBackgroundService().sendData({
                "type": "GetAccountStateAction"
            });
            */

            store.dispatch(NavigateToAction.replace(conversationsRoute));
          } else {
            store.dispatch(NavigateToAction.replace(loginRoute));
          }
        }
        break;
        case "LoginSuccessfulEvent": {
          store.dispatch(
            LoginSuccessfulAction(
              jid: data["jid"]!,
              displayName: data["displayName"]!
            )
          );
        }
        break;
        case "ConversationCreatedEvent": {
          store.dispatch(AddConversationAction(
              conversation: Conversation.fromJson(data["conversation"]!)
            )
          );
        }
        break;
        case "ConversationUpdatedEvent": {
          store.dispatch(
            UpdateConversationAction(
              conversation: Conversation.fromJson(data["conversation"]!)
            )
          );
        }
        break;
        case "MessageReceivedEvent": {
          store.dispatch(
            AddMessageAction(
              message: Message.fromJson(data["message"]!)
            )
          );
        }
        break;
        case "LoadRosterItemsResult": {
          final List<RosterItem> tmp = List<RosterItem>.from(data["items"]!.map((i) => RosterItem.fromJson(i)));
          store.dispatch(
            AddMultipleRosterItemsAction(
              items: tmp
            )
          );
        }
        break;
        case "LoadConversationsResult": {
          final List<Conversation> tmp = List<Conversation>.from(data["conversations"]!.map((c) => Conversation.fromJson(c)));
          store.dispatch(AddMultipleConversationsAction(
              conversations: tmp
          ));
        }
        break;
        case "LoadMessagesForJidResult": {
          final List<Message> tmp = List<Message>.from(data["messages"]!.map((m) => Message.fromJson(m)));
          store.dispatch(
            AddMultipleMessagesAction(
              conversationJid: data["jid"]!,
              messages: tmp,
              replace: true
            )
          );
        }
        break;
        case "AddToRosterResult": {
          store.dispatch(
            AddToRosterDoneAction(
              result: data["result"]!,
              msg: data["msg"],
              jid: data["jid"]
            )
          );
        }
        break;
        case "RosterItemModifiedEvent": {
          store.dispatch(
            ModifyRosterItemAction(
              item: RosterItem.fromJson(data["item"]!)
            )
          );
        }
        break;
        case "MessageSendResult": {
          store.dispatch(
            AddMessageAction(
              message: Message.fromJson(data["message"]!)
            )
          );
        }
        break;
        case "__LOG__": {
          // TODO: Use logging function and only print on when debugging
          // ignore: avoid_print
          print("[S] " + data["log"]!);
        }
        break;
      }
  });
  
  runApp(MyApp(store: store));
}

class MyApp extends StatefulWidget {
  final Store<MoxxyState> store;

  const MyApp({Key? key, required this.store }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _MyAppState createState() => _MyAppState(store: store);
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final Store<MoxxyState> store;

  _MyAppState({ required this.store });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
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
        FlutterBackgroundService().sendData({
            "type": "SetCSIState",
            "state": "background"
        });
        break;
      case AppLifecycleState.resumed:
        FlutterBackgroundService().sendData({
            "type": "SetCSIState",
            "state": "foreground"
        });
        break;
      default: break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
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
          )
        ),
        navigatorKey: NavigatorHolder.navigatorKey,
        //themeMode: ThemeMode.system,
        themeMode: ThemeMode.dark,
        routes: {
          introRoute: (context) => const IntroPage(),
          loginRoute: (context) => LoginPage(),
          registrationRoute: (context) => RegistrationPage(),
          postRegistrationRoute: (context) => const PostRegistrationPage(),
          conversationsRoute: (context) => const ConversationsPage(),
          conversationRoute: (context) => const ConversationPage(),
          profileRoute: (context) => const ProfilePage(),
          sendFilesRoute: (context) => const SendFilesPage(),
          newConversationRoute: (context) => const NewConversationPage(),
          addContactRoute: (context) => AddContactPage(),
          settingsRoute: (context) => const SettingsPage(),
          licensesRoute: (context) => const SettingsLicensesPage(),
          aboutRoute: (context) => const SettingsAboutPage(),
        },
        home: const SplashScreen(),
      )
    );
  }
}
