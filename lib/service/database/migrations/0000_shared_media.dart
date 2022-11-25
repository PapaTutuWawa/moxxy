import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV5ToV6(Database db) async {
  // Allow shared media to reference a message
  await db.execute(
    'ALTER TABLE $mediaTable ADD COLUMN message_id INTEGER REFERENCES $messagesTable (id);',
  );
}
