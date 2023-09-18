import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV10ToV11(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    "ALTER TABLE $messagesTable ADD COLUMN reactions TEXT NOT NULL DEFAULT '[]';",
  );
}
