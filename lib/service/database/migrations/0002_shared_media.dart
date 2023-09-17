import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV33ToV34(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Remove the shared media counter...
  await db.execute(
    'ALTER TABLE $conversationsTable DROP COLUMN sharedMediaAmount',
  );

  // ... and the entire table.
  await db.execute(
    'DROP TABLE $mediaTable',
  );
}
