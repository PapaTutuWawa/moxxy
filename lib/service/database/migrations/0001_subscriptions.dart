import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV26ToV27(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute('''
    CREATE TABLE $subscriptionsTable(
      jid TEXT PRIMARY KEY
    )''');
}
