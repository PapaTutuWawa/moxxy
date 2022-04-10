import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/xmpp/xeps/xep_0085.dart";

part "events.g.dart";

const preStartLoggedInState = "logged_in";
const preStartNotLoggedInState = "not_logged_in";

class BackgroundEvent implements JsonImplementation {
  // NOTE: This is just to make the type system happy
  @override
  Map<String, dynamic> toJson() => {};
}
