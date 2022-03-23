import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";
import "package:permission_handler/permission_handler.dart";

Future<void> performLoginHandler(BaseEvent c, { dynamic extra }) async {
  final command = c as LoginCommand;
  final id = extra as String;

  GetIt.I.get<Logger>().fine("Performing login");
  final result = await GetIt.I.get<XmppService>().connectAwaitable(
    ConnectionSettings(
      jid: JID.fromString(command.jid),
      password: command.password,
      useDirectTLS: command.useDirectTLS,
      allowPlainAuth: false
    ), true
  );

  if (result.success) {
    final settings = GetIt.I.get<XmppConnection>().getConnectionSettings();
    sendEvent(
      LoginSuccessfulEvent(
        jid: settings.jid.toString(),
        displayName: settings.jid.local
      ),
      id:id
    );
  } else {
    sendEvent(
      LoginFailureEvent(
        reason: result.reason!
      ),
      id: id
    );
  }
}

Future<void> performPreStart(BaseEvent c, { dynamic extra }) async {
  final command = c as PerformPreStartCommand;
  final id = extra as String;
  
  final xmpp = GetIt.I.get<XmppService>();
  final account = await xmpp.getAccountData();
  final settings = await xmpp.getConnectionSettings();
  final state = await xmpp.getXmppState();
  final preferences = await GetIt.I.get<PreferencesService>().getPreferences();


  GetIt.I.get<Logger>().finest("account != null: " + (account != null).toString());
  GetIt.I.get<Logger>().finest("settings != null: " + (settings != null).toString());

  if (account!= null && settings != null) {
    await GetIt.I.get<RosterService>().loadRosterFromDatabase();

    // Check some permissions
    final storagePerm = await Permission.storage.status;
    final List<int> permissions = List.empty(growable: true);
    if (storagePerm.isDenied /*&& !state.askedStoragePermission*/) {
      permissions.add(Permission.storage.value);

      await xmpp.modifyXmppState((state) => state.copyWith(
          askedStoragePermission: true
      ));
    }
    
    sendEvent(
      PreStartDoneEvent(
        state: "logged_in",
        jid: account.jid,
        displayName: account.displayName,
        avatarUrl: state.avatarUrl,
        debugEnabled: state.debugEnabled,
        permissionsToRequest: permissions,
        preferences: preferences,
        conversations: await GetIt.I.get<DatabaseService>().loadConversations(),
        roster: await GetIt.I.get<RosterService>().loadRosterFromDatabase()
      ),
      id: id
    );
  } else {
    sendEvent(
      PreStartDoneEvent(
        state: "not_logged_in",
        debugEnabled: state.debugEnabled,
        permissionsToRequest: List<int>.empty(),
        preferences: preferences
      ),
      id: id
    );
  }
}

Future<void> performAddConversation(BaseEvent c, { dynamic extra }) async {
  final command = c as AddConversationCommand;
  final id = extra as String;

  final db = GetIt.I.get<DatabaseService>();
  final conversation = await db.getConversationByJid(command.jid);
  if (conversation != null) {
    if (!conversation.open) {
      // Re-open the conversation
      final updatedConversation = await db.updateConversation(
        id: conversation.id,
        open: true
      );

      sendEvent(
        ConversationAddedEvent(
          conversation: updatedConversation
        ),
        id: id
      );
      return;
    }

    sendEvent(
      NoConversationModifiedEvent(),
      id: id
    );
    return;
  } else {
    final conversation = await db.addConversationFromData(
      command.title,
      command.lastMessageBody,
      command.avatarUrl,
      command.jid,
      0,
      -1,
      const [],
      true
    );

    sendEvent(
      ConversationAddedEvent(
        conversation: conversation
      ),
      id: id
    );
  }
}
