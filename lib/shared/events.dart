import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/message.dart";

import "package:moxplatform/types.dart";
import "package:moxlib/awaitabledatasender.dart";

part "events.g.dart";

const preStartLoggedInState = "logged_in";
const preStartNotLoggedInState = "not_logged_in";
