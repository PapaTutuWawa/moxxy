import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV11ToV12(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN containsNoStore INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
