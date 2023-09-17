import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV29ToV30(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN sharedMediaAmount INTEGER NOT NULL DEFAULT 0;',
  );

  // Get all conversations
  final conversations = await db.query(
    conversationsTable,
  );

  for (final conversation in conversations) {
    // Count the amount of shared media
    final jid = conversation['jid']! as String;
    final result = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $mediaTable WHERE conversation_jid = ?',
            [jid],
          ),
        ) ??
        0;

    final c = Map<String, Object?>.from(conversation)..remove('id');
    await db.update(
      conversationsTable,
      {
        ...c,
        'sharedMediaAmount': result,
      },
      where: 'jid = ?',
      whereArgs: [jid],
    );
  }
}
