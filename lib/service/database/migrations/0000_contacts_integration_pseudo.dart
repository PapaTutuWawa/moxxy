import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV15ToV16(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $rosterTable ADD COLUMN pseudoRosterItem INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
