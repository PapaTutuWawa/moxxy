import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/service/service.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";

Future<void> performLoginHandler(BaseEvent c, { dynamic extra }) async {
  final command = c as LoginCommand;
  GetIt.I.get<Logger>().fine("Performing login");
  // TODO: Check if everything worked
  // TODO
  /*
  await GetIt.I.get<XmppService>().connect(
    ConnectionSettings(
      jid: JID.fromString(command.jid),
      password: command.password,
      useDirectTLS: command.useDirectTLS,
      allowPlainAuth: false
    ),
    true
  );*/

  // TODO: Remove
  sendEvent(
    LoginSuccessfulEvent(
      jid: "test@example.com",
      displayName: "test"
    ),
    id: extra as String
  );
}
