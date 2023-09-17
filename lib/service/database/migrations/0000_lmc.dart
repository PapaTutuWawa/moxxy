import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV9ToV10(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Mark all messages as not edited
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN isEdited INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
