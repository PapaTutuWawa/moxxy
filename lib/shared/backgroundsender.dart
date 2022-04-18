import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";

import "package:flutter_background_service/flutter_background_service.dart";
import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

/// An [AwaitableDataSender] that uses flutter_background_service.
class BackgroundServiceDataSender extends AwaitableDataSender<BackgroundCommand, BackgroundEvent> {
  final FlutterBackgroundService _srv;

  BackgroundServiceDataSender() : _srv = FlutterBackgroundService(), super();

  @override
  Future<void> sendDataImpl(DataWrapper data) async {
    _srv.invoke("command", data.toJson());
    GetIt.I.get<Logger>().finest("Sending ${data.toString()} to service");
  }
}
