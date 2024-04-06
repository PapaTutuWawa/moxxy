import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV49ToV50(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN favourite DEFAULT ${boolToInt(false)}',
  );
}
