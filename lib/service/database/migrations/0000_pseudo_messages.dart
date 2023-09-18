import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV23ToV24(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN pseudoMessageType INTEGER;',
  );
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN pseudoMessageData TEXT;',
  );
}
