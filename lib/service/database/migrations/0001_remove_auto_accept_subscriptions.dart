import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV28ToV29(Database db) async {
  await db.delete(
    preferenceTable,
    where: 'key = "autoAcceptSubscriptionRequests"',
  );
}
