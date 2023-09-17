import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV19ToV20(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $stickerPacksTable ADD COLUMN restricted DEFAULT ${boolToInt(false)};',
  );
  await db.execute(
    'ALTER TABLE $stickersTable ADD COLUMN suggests DEFAULT "";',
  );
}
