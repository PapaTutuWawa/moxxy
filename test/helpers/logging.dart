import 'package:logging/logging.dart';

/// Enable logging using logger.
void initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
        '[${record.level.name}] (${record.loggerName}) ${record.time}: ${record.message}');
  });
}
