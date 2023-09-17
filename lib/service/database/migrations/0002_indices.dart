import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV36ToV37(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Queries against messages by id (and sid/originId happen regularly)
  await db.execute(
    'CREATE INDEX idx_messages_id ON $messagesTable (id, sid, originId)',
  );

  // Conversations are often queried by their jid
  await db.execute(
    'CREATE INDEX idx_conversation_id ON $conversationsTable (jid)',
  );

  // Reactions must be quickly queried
  await db.execute(
    'CREATE INDEX idx_reactions_message_id ON $reactionsTable (message_id, senderJid)',
  );

  // File metadata should also be quickly queriable by its id
  await db.execute(
    'CREATE INDEX idx_file_metadata_message_id ON $fileMetadataTable (id)',
  );
}
