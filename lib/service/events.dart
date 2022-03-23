import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";

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
    ),
    true
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
