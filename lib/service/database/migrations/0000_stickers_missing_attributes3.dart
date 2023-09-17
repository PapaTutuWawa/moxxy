import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV21ToV22(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $stickersTable DROP COLUMN suggests;',
  );

  await db.execute(
    'ALTER TABLE $stickersTable ADD COLUMN suggests TEXT NOT NULL DEFAULT "{}";',
  );
}
