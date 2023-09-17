import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV28ToV29(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.delete(
    preferenceTable,
    where: 'key = "autoAcceptSubscriptionRequests"',
  );
}
