import "dart:async";

import "package:moxxyv2/backend/account.dart";
import "package:moxxyv2/repositories/database.dart";
import "package:moxxyv2/repositories/xmpp.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:isar/isar.dart";

import "package:moxxyv2/isar.g.dart";

Future<void> initializeServiceIfNeeded() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = FlutterBackgroundService();
  if (await service.isServiceRunning()) {
    if (kDebugMode) {
      // TODO: Stop the background service
    }
  }
  
  GetIt.I.registerSingleton<FlutterBackgroundService>(await initializeService());
}

void Function(Map<String, dynamic>) sendDataMiddleware(FlutterBackgroundService srv) {
  return (data) {
    // NOTE: *S*erver to *F*oreground
    print("[S2F] " + data.toString());

    srv.sendData(data);
  };
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  service.onDataReceived.listen(handleEvent);
  service.setNotificationInfo(title: "Moxxy", content: "Connecting...");

  service.sendData({ "type": "__LOG__", "log": "Running" });

  GetIt.I.registerSingleton<FlutterBackgroundService>(service);
  
  (() async {
      final middleware = sendDataMiddleware(service);

      // Register singletons
      final db = DatabaseRepository(isar: await openIsar(), sendData: middleware);
      GetIt.I.registerSingleton<DatabaseRepository>(db); 

      final xmpp = XmppRepository(sendData: (data) {
          if (data["type"] == "ConnectionStateEvent") {
            if (data["state"] == "CONNECTED") {
              service.setNotificationInfo(title: "Moxxy", content: "Ready to receive messages");
            } else if (data["state"] == "CONNECTING") {
              service.setNotificationInfo(title: "Moxxy", content: "Connecting...");
            } else {
              service.setNotificationInfo(title: "Moxxy", content: "Disconnected");
            }
          }

          middleware(data);
      });
      GetIt.I.registerSingleton<XmppRepository>(xmpp);
      GetIt.I.registerSingleton<RosterRepository>(RosterRepository(sendData: service.sendData));

      final connection = XmppConnection(log: (data) {
          service.sendData({ "type": "__LOG__", "log": data });
      });
      GetIt.I.registerSingleton<XmppConnection>(connection);

      final account = await getAccountData();
      final settings = await xmpp.loadConnectionSettings();

      if (account!= null && settings != null) {
        await GetIt.I.get<RosterRepository>().loadRosterFromDatabase();

        middleware({
            "type": "__LOG__",
            "log": "Connecting..."
        });
        xmpp.connect(settings, false);
        middleware({
            "type": "PreStartResult",
            "state": "logged_in"
        });
      } else {
        middleware({
            "type": "PreStartResult",
            "state": "not_logged_in"
        });
      }
  })();
}

Future<FlutterBackgroundService> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    // TODO: iOS
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onBackground: () {},
      onForeground: () {}
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true
    )
  );

  return service;
}

void handleEvent(Map<String, dynamic>? data) {
  // NOTE: *F*oreground to *S*ervice
  print("[F2S] " + data.toString());

  switch (data!["type"]) {
    case "LoadConversationsAction": {
      GetIt.I.get<DatabaseRepository>().loadConversations();
    }
    break;
    case "LoadRosterAction": {
      GetIt.I.get<DatabaseRepository>().loadRosterItems(notify: true);
    }
    break;
    case "PerformLoginAction": {
      GetIt.I.get<FlutterBackgroundService>().sendData({ "type": "__LOG__", "log": "Performing login"});
      GetIt.I.get<XmppRepository>().connect(ConnectionSettings(
          jid: BareJID.fromString(data["jid"]!),
          password: data["password"]!,
          useDirectTLS: data["useDirectTLS"]!,
          allowPlainAuth: data["allowPlainAuth"],
          streamResumptionSettings: StreamResumptionSettings()
      ), true);
    }
    break;
    case "LoadMessagesForJidAction": {
      GetIt.I.get<DatabaseRepository>().loadMessagesForJid(data["jid"]);
    }
    break;
    case "SetCurrentlyOpenChatAction": {
      GetIt.I.get<XmppRepository>().setCurrentlyOpenedChatJid(data["jid"]);
    }
    break;
    case "AddToRosterAction": {
      final String jid = data["jid"];
      (() async {
          final roster = GetIt.I.get<RosterRepository>();
          if (await roster.isInRoster(jid)) {
            FlutterBackgroundService().sendData({
                "type": "AddToRosterResult",
                "result": "error",
                "msg": "Already in contact list"
            });
            return;
          }

          final db = GetIt.I.get<DatabaseRepository>();
          final conversation = await db.getConversationByJid(jid);
          if (conversation != null) {
            final c = await db.updateConversation(id: conversation.id, open: true);
            FlutterBackgroundService().sendData({
                "type": "ConversationUpdatedEvent",
                "conversation": c.toJson()
            });
          } else {
            final c = await db.addConversationFromData(
              jid.split("@")[0],
              "",
              "",
              jid,
              0,
              -1,
              [],
              true
            );
            FlutterBackgroundService().sendData({
                "type": "ConversationCreatedEvent",
                "conversation": c.toJson()
            });
          }
          
          await roster.addToRoster("", jid, jid.split("@")[0]);
          FlutterBackgroundService().sendData({
              "type": "AddToRosterResult",
              "result": "success",
              "jid": jid
          });
      })();
    }
    break;
    case "RemoveRosterItemAction": {
      (() async {
          final jid = data["jid"]!;
          //await GetIt.I.get<DatabaseRepository>().removeRosterItemByJid(jid, nullOkay: true);
          await GetIt.I.get<XmppConnection>().removeFromRoster(jid);
          await GetIt.I.get<XmppConnection>().sendUnsubscriptionRequest(jid);
      })();
    }
    break;
    case "__STOP__": {
      FlutterBackgroundService().stopBackgroundService();
    }
    break;
  }
}
