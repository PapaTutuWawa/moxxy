import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV33ToV34(Database db) async {
  // Remove the shared media counter...
  await db.execute(
    'ALTER TABLE $conversationsTable DROP COLUMN sharedMediaAmount',
  );

  // ... and the entire table.
  await db.execute(
    'DROP TABLE $mediaTable',
  );
}
