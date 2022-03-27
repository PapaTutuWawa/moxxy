import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/models/message.dart";

part "commands.g.dart";

abstract class BackgroundCommand implements JsonImplementation {}
