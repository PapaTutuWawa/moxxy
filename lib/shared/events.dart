import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/message.dart";

part "events.g.dart";

const preStartLoggedInState = "logged_in";
const preStartNotLoggedInState = "not_logged_in";

class BackgroundEvent extends BaseEvent implements JsonImplementation {
  // NOTE: This is just to make the type system happy
  Map<String, dynamic> toJson() => {};
}
