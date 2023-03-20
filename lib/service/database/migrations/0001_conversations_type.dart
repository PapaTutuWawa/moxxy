import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV30ToV31(Database db) async {
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN type TEXT NOT NULL DEFAULT "chat";',
  );
}
