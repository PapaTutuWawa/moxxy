import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV35ToV36(Database db) async {
  await db.execute('DROP TABLE $reactionsTable');
  await db.execute('''
    CREATE TABLE $reactionsTable (
      senderJid  TEXT NOT NULL,
      emoji      TEXT NOT NULL,
      message_id INTEGER NOT NULL,
      CONSTRAINT pk_sender PRIMARY KEY (senderJid, emoji, message_id),
      CONSTRAINT fk_message FOREIGN KEY (message_id) REFERENCES $messagesTable (id)
        ON DELETE CASCADE
    )''');
}
