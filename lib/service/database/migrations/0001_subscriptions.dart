import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV26ToV27(Database db) async {
  await db.execute(
    '''
    CREATE TABLE $subscriptionsTable(
      jid TEXT PRIMARY KEY
    )'''
  );
}
