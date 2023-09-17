import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV38ToV39(DatabaseMigrationData data) async {
  final (db, _) = data;
  await db.execute('DROP TABLE $subscriptionsTable');
}
