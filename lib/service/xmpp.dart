import "dart:async";

import "package:moxxyv2/backend/account.dart";
import "package:moxxyv2/repositories/database.dart";
import "package:moxxyv2/repositories/xmpp.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/0030.dart";
import "package:moxxyv2/xmpp/xeps/0198.dart";
import "package:moxxyv2/xmpp/xeps/0352.dart";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:isar/isar.dart";
import "package:awesome_notifications/awesome_notifications.dart";

import "package:moxxyv2/isar.g.dart";

class MoxxyStreamManagementManager extends StreamManagementManager {
  @override
  Future<void> commitClientSeq() async {
    await GetIt.I.get<XmppRepository>().saveStreamManagementLastH(getClientStanzaSeq());
  }

  @override
  Future<void> loadClientSeq() async {
    final seq = await GetIt.I.get<XmppRepository>().getStreamManagementLastH();
    setClientSeq(seq ?? 0);
  }

  @override
  Future<void> commitStreamResumptionId() async {
    final srid = getStreamResumptionId();
    if (srid !=  null) {
      await GetIt.I.get<XmppRepository>().saveStreamResumptionId(srid);
    }
  }

  @override
  Future<void> loadStreamResumptionId() async {
    final id = await GetIt.I.get<XmppRepository>().getStreamResumptionId();
    if (id != null) {
      setStreamResumptionId(id);
    }
  }
}

Future<void> initializeServiceIfNeeded() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = FlutterBackgroundService();
  if (await service.isServiceRunning()) {
    if (kDebugMode) {
      // TODO: Stop the background service
    } else {
      // TODO: Just don't run initializeService again
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
              FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Ready to receive messages");
            } else if (data["state"] == "CONNECTING") {
              FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Connecting...");
            } else {
              FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Disconnected");
            }
          }

          middleware(data);
      });
      GetIt.I.registerSingleton<XmppRepository>(xmpp);
      GetIt.I.registerSingleton<RosterRepository>(RosterRepository(sendData: service.sendData));

      final connection = XmppConnection(log: (data) {
          service.sendData({ "type": "__LOG__", "log": data });
      });
      connection.registerManager(MoxxyStreamManagementManager());
      connection.registerManager(DiscoManager());
      connection.registerManager(MessageManager());
      connection.registerManager(RosterManager());
      connection.registerManager(PresenceManager());
      connection.registerManager(CSIManager());
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
          allowPlainAuth: data["allowPlainAuth"]
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

          roster.addToRoster("", jid, jid.split("@")[0]);
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
          await GetIt.I.get<XmppConnection>().getManagerById(ROSTER_MANAGER)!.removeFromRoster(jid);
          await GetIt.I.get<XmppConnection>().getManagerById(ROSTER_MANAGER)!.sendUnsubscriptionRequest(jid);
      })();
    }
    break;
    case "SendMessageAction": {
      GetIt.I.get<XmppRepository>().sendMessage(body: data["body"]!, jid: data["jid"]!);
    }
    break;
    case "SetCSIState": {
      final csi = GetIt.I.get<XmppConnection>().getManagerById(CSI_MANAGER);
      if (csi == null) {
        return;
      }

      if (data["state"] == "foreground") {
        csi.setActive();
      } else {
        csi.setInactive();
      }
    }
    break;
    case "__STOP__": {
      FlutterBackgroundService().stopBackgroundService();
    }
    break;
  }
}
