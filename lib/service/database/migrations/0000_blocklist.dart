import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV22ToV23(Database db) async {
  await db.execute(
    '''
    CREATE TABLE $blocklistTable (
      jid TEXT PRIMARY KEY
    );
    ''',
  );
}
