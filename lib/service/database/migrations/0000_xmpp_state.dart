import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV1ToV2(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Create the table
  await db.execute(
    '''
    CREATE TABLE $xmppStateTable (
      key   TEXT PRIMARY KEY,
      value TEXT
    )''',
  );
}
