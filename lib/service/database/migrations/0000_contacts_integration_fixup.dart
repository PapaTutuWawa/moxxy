import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV14ToV15(Database db) async {
  // Add the missing primary key
  await db.execute(
    '''
    CREATE TABLE ${contactsTable}_new (
      id TEXT PRIMARY KEY
    )''',
  );
  await db.execute('INSERT INTO ${contactsTable}_new SELECT * from $contactsTable');
  await db.execute('DROP TABLE $contactsTable;');
  await db.execute('ALTER TABLE ${contactsTable}_new RENAME TO $contactsTable;');
}
