import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV22ToV23(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    '''
    CREATE TABLE $blocklistTable (
      jid TEXT PRIMARY KEY
    );
    ''',
  );
}
