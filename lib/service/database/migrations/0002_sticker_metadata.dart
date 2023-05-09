import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> migrateFromV32ToV33(Database db) async {
  final stickers = await db.query(stickersTable);

  await db.execute(
    '''
    CREATE TABLE ${stickersTable}_new (
      id               TEXT PRIMARY KEY,
      desc             TEXT NOT NULL,
      suggests         TEXT NOT NULL,
      file_metadata_id TEXT NOT NULL,
      stickerPackId  TEXT NOT NULL,
      CONSTRAINT fk_sticker_pack FOREIGN KEY (stickerPackId) REFERENCES $stickerPacksTable (id)
        ON DELETE CASCADE,
      CONSTRAINT fk_file_metadata FOREIGN KEY (file_metadata_id) REFERENCES $fileMetadataTable (id)
    )''',
  );

  // Mapping stickerHashKey -> fileMetadataId
  final stickerHashMap = <String, String>{};
  for (final sticker in stickers) {
    final hashes =
        (jsonDecode(sticker['hashes']! as String) as Map<String, dynamic>)
            .cast<String, String>();

    final buffer = StringBuffer();
    for (var i = 0; i < hashes.length; i++) {
      buffer.write('(algorithm = ? AND value = ?) AND');
    }
    final query = buffer.toString();

    final rawFm = await db.query(
      fileMetadataHashesTable,
      where: query.substring(0, query.length - 1 - 3),
      whereArgs: hashes.entries
          .map<List<String>>((entry) => [entry.key, entry.value])
          .flattened
          .toList(),
      limit: 1,
    );

    String fileMetadataId;
    if (rawFm.isEmpty) {
      // Create the metadata
      fileMetadataId = DateTime.now().toString();
      await db.insert(
        fileMetadataTable,
        {
          'id': fileMetadataId,
          'path': sticker['path']! as String,
          'size': sticker['size']! as int,
          'width': sticker['width'] as int?,
          'height': sticker['height'] as int?,
          'plaintextHashes': sticker['hashes']! as String,
          'mimeType': sticker['mediaType']! as String,
          'sourceUrls': sticker['urlSources'],
          'filename': path.basename(sticker['path']! as String),
        },
      );

      // Create hash pointers
      for (final hashEntry in hashes.entries) {
        await db.insert(
          fileMetadataHashesTable,
          {
            'algorithm': hashEntry.key,
            'value': hashEntry.value,
            'id': fileMetadataId,
          },
        );
      }
    } else {
      fileMetadataId = rawFm.first['id']! as String;
    }

    final hashKey = sticker['hashKey']! as String;
    stickerHashMap[hashKey] = fileMetadataId;
    await db.insert(
      '${stickersTable}_new',
      {
        'id': hashKey,
        'desc': sticker['desc']! as String,
        'suggests': sticker['suggests']! as String,
        'file_metadata_id': fileMetadataId,
        'stickerPackId': sticker['stickerPackId']! as String,
      },
    );
  }

  // Rename the table
  await db.execute('DROP TABLE $stickersTable');
  await db.execute('ALTER TABLE ${stickersTable}_new RENAME TO $stickersTable');

  // Migrate messages
  for (final stickerEntry in stickerHashMap.entries) {
    await db.update(
      messagesTable,
      {
        'file_metadata_id': stickerEntry.value,
      },
      where: 'stickerHashKey = ?',
      whereArgs: [stickerEntry.key],
    );
  }

  // Remove the hash key from messages
  await db.execute('ALTER TABLE $messagesTable DROP COLUMN stickerHashKey');
}
