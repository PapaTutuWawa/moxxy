import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV42ToV43(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    '''
    CREATE TABLE $groupchatTable (
      jid TEXT PRIMARY KEY,
      nick TEXT NOT NULL
    )''',
  );
}
