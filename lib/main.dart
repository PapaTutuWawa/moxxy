import "ui/pages/conversation/conversation.dart";
import "ui/pages/conversations.dart";
import "ui/pages/profile/profile.dart";
import "ui/pages/newconversation.dart";
import "ui/pages/login/login.dart";
import "ui/pages/register/register.dart";
import "ui/pages/intro.dart";
import "ui/pages/addcontact/addcontact.dart";
import "ui/pages/postregister/postregister.dart";
import "ui/pages/sendfiles.dart";
import "ui/pages/settings/settings.dart";
import "ui/pages/settings/licenses.dart";
import "ui/pages/settings/about.dart";
import "ui/constants.dart";
import "redux/conversation/actions.dart";
import "redux/conversation/reducers.dart";
import "redux/conversation/actions.dart";
import "redux/start/actions.dart";
import "redux/conversations/middlewares.dart";
import "redux/account/middlewares.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "redux/start/middlewares.dart";
import "redux/login/middlewares.dart";
import "redux/login/actions.dart";
import "redux/registration/middlewares.dart";
import "redux/addcontact/middlewares.dart";
import "redux/addcontact/actions.dart";
import "redux/roster/middlewares.dart";
import "redux/roster/actions.dart";
import "redux/messages/middleware.dart";
import "redux/conversation/middlewares.dart";
import "redux/state.dart";
import "models/conversation.dart";
import "models/message.dart";
import "models/roster.dart";
import "backend/account.dart";
import "service/xmpp.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:redux_logging/redux_logging.dart";
import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:awesome_notifications/awesome_notifications.dart";

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
      NavigationMiddleware(),

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

  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    // TODO: Add icon
    null,
    [
      NotificationChannel(
        channelGroupKey: "messages",
        channelKey: "message_channel",
        channelName: "Message notifications",
        channelDescription: "Notifications for messages go here",
        importance: NotificationImportance.High
      )
    ],
    debug: true
  );

  await initializeServiceIfNeeded();
  
  GetIt.I.get<FlutterBackgroundService>().onDataReceived.listen((data) {
      if (data!["type"]! != "__LOG__") {
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

            (() async {
                final state = await getAccountData();
                store.dispatch(SetAccountAction(state: state!));
            })();
            
            store.dispatch(NavigateToAction.replace("/conversations"));
          } else {
            store.dispatch(NavigateToAction.replace("/intro"));
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
          print("[S] " + data["log"]!);
        }
        break;
      }
  });
  
  runApp(MyApp(store: store));
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
  final Store<MoxxyState> store;

  MyApp({ required this.store });
  
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: this.store,
      child: MaterialApp(
        title: "Moxxy",
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
