import 'dart:convert';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV34ToV35(Database db) async {
  // Create the table
  await db.execute('''
    CREATE TABLE $reactionsTable (
      senderJid  TEXT NOT NULL,
      emoji      TEXT NOT NULL,
      message_id INTEGER NOT NULL,
      CONSTRAINT pk_sender PRIMARY KEY (senderJid, emoji, message_id),
      CONSTRAINT fk_message FOREIGN KEY (message_id) REFERENCES $messagesTable (id)
        ON DELETE CASCADE
    )''');

  // Figure out our JID
  final rawJid = await db.query(
    xmppStateTable,
    where: "key = 'jid'",
    limit: 1,
  );
  String? jid;
  if (rawJid.isNotEmpty) {
    jid = rawJid.first['value']! as String;
  }

  // Migrate messages
  final messages = await db.query(
    messagesTable,
    where: "reactions IS NOT '[]'",
  );
  for (final message in messages) {
    final reactions =
        (jsonDecode(message['reactions']! as String) as List<dynamic>)
            .cast<Map<String, Object?>>();

    for (final reaction in reactions) {
      final senders = [
        ...reaction['senders']! as List<String>,
        if (intToBool(reaction['reactedBySelf']! as int) && jid != null) jid,
      ];

      for (final sender in senders) {
        await db.insert(
          reactionsTable,
          {
            'senderJid': sender,
            'emoji': reaction['emoji']! as String,
            'message_id': message['id']! as int,
          },
        );
      }
    }
  }

  // Remove the column
  await db.execute('ALTER TABLE $messagesTable DROP COLUMN reactions');
}
