import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV5ToV6(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Allow shared media to reference a message
  await db.execute(
    'ALTER TABLE $mediaTable ADD COLUMN message_id INTEGER REFERENCES $messagesTable (id);',
  );
}
