import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV3ToV4(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Mark all messages as not retracted
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN isRetracted INTEGER DEFAULT ${boolToInt(false)};',
  );
}
