import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV38ToV39(Database db) async {
  await db.execute('DROP TABLE $subscriptionsTable');
}
