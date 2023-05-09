import 'dart:convert';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/files.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV31ToV32(Database db) async {
  // Create the tracking table
  await db.execute('''
    CREATE TABLE $fileMetadataTable (
      id               TEXT NOT NULL PRIMARY KEY,
      path             TEXT,
      sourceUrls       TEXT,
      mimeType         TEXT,
      thumbnailType    TEXT,
      thumbnailData    TEXT,
      width            INTEGER,
      height           INTEGER,
      plaintextHashes  TEXT,
      encryptionKey    TEXT,
      encryptionIv     TEXT,
      encryptionScheme TEXT,
      cipherTextHashes TEXT,
      filename         TEXT NOT NULL,
      size             INTEGER
    )''');
  await db.execute('''
    CREATE TABLE $fileMetadataHashesTable (
      algorithm TEXT NOT NULL,
      value     TEXT NOT NULL,
      id        TEXT NOT NULL,
      CONSTRAINT f_primarykey PRIMARY KEY (algorithm, value),
      CONSTRAINT fk_id FOREIGN KEY (id) REFERENCES $fileMetadataTable (id)
        ON DELETE CASCADE
    )''');

  // Add the file_metadata_id column
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN file_metadata_id TEXT DEFAULT NULL;',
  );

  // Migrate the media messages' attributes to new table
  final messages = await db.query(
    messagesTable,
    where: 'isMedia = ${boolToInt(true)}',
  );
  for (final message in messages) {
    // Do we know of a hash?
    String id;
    if (message['plaintextHashes'] != null) {
      // Plaintext hashes available (SFS)
      final plaintextHashes = (jsonDecode(message['plaintextHashes']! as String)
              as Map<dynamic, dynamic>)
          .cast<String, String>();
      final result = await db.query(
        fileMetadataHashesTable,
        where: 'algorithm = ? AND value = ?',
        whereArgs: [
          plaintextHashes.entries.first.key,
          plaintextHashes.entries.first.value,
        ],
        limit: 1,
      );

      if (result.isEmpty) {
        final metadata = FileMetadata(
          getStrongestHashFromMap(plaintextHashes) ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          message['mediaUrl'] as String?,
          message['srcUrl'] != null ? [message['srcUrl']! as String] : null,
          message['mediaType'] as String?,
          message['mediaSize'] as int?,
          message['thumbnailData'] != null ? 'blurhash' : null,
          message['thumbnailData'] as String?,
          message['mediaWidth'] as int?,
          message['mediaHeight'] as int?,
          plaintextHashes,
          message['key'] as String?,
          message['iv'] as String?,
          message['encryptionScheme'] as String?,
          message['plaintextHashes'] == null
              ? null
              : (jsonDecode(message['ciphertextHashes']! as String)
                      as Map<dynamic, dynamic>)
                  .cast<String, String>(),
          message['filename']! as String,
        );

        // Create the metadata
        await db.insert(
          fileMetadataTable,
          metadata.toDatabaseJson(),
        );
        id = metadata.id;
      } else {
        id = result[0]['id']! as String;
      }
    } else {
      // No plaintext hashes are available (OOB data)
      int? size;
      int? height;
      int? width;
      Map<String, String>? hashes;
      String? filePath;
      String? urlSource;
      String? mediaType;
      String? filename;
      if (message['filename'] == null) {
        // We are dealing with a sticker
        assert(
          message['stickerPackId'] != null,
          'The message must contain a sticker',
        );
        assert(
          message['stickerHashKey'] != null,
          'The message must contain a sticker',
        );
        final sticker = (await db.query(
          stickersTable,
          where: 'stickerPackId = ? AND hashKey = ?',
          whereArgs: [message['stickerPackId'], message['stickerHashKey']],
          limit: 1,
        ))
            .first;
        size = sticker['size']! as int;
        width = sticker['width'] as int?;
        height = sticker['height'] as int?;
        hashes =
            (jsonDecode(sticker['hashes']! as String) as Map<String, dynamic>)
                .cast<String, String>();
        filePath = sticker['path']! as String;
        urlSource =
            ((jsonDecode(sticker['urlSources']! as String) as List<dynamic>)
                    .cast<String>())
                .first;
        mediaType = sticker['mediaType']! as String;
        filename = path.basename(sticker['path']! as String);
      } else {
        size = message['mediaSize'] as int?;
        width = message['mediaWidth'] as int?;
        height = message['mediaHeight'] as int?;
        filePath = message['mediaUrl'] as String?;
        urlSource = message['srcUrl'] as String?;
        mediaType = message['mediaType'] as String?;
        filename = message['filename'] as String?;
      }

      final metadata = FileMetadata(
        DateTime.now().millisecondsSinceEpoch.toString(),
        filePath,
        urlSource != null ? [urlSource] : null,
        mediaType,
        size,
        message['thumbnailData'] != null ? 'blurhash' : null,
        message['thumbnailData'] as String?,
        width,
        height,
        hashes,
        message['key'] as String?,
        message['iv'] as String?,
        message['encryptionScheme'] as String?,
        null,
        filename!,
      );

      // Create the metadata
      await db.insert(
        fileMetadataTable,
        metadata.toDatabaseJson(),
      );
      id = metadata.id;
    }

    // Update the message
    await db.update(
      messagesTable,
      {
        'file_metadata_id': id,
      },
    );
  }

  // Remove columns and add foreign key
  await db.execute(
    '''
    CREATE TABLE ${messagesTable}_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender TEXT NOT NULL,
      body TEXT,
      timestamp INTEGER NOT NULL,
      sid TEXT NOT NULL,
      conversationJid TEXT NOT NULL,
      isFileUploadNotification INTEGER NOT NULL,
      encrypted INTEGER NOT NULL,
      errorType INTEGER,
      warningType INTEGER,
      received INTEGER,
      displayed INTEGER,
      acked INTEGER,
      originId TEXT,
      quote_id INTEGER,
      file_metadata_id TEXT,
      isDownloading INTEGER NOT NULL,
      isUploading INTEGER NOT NULL,
      isRetracted INTEGER,
      isEdited INTEGER NOT NULL,
      reactions TEXT NOT NULL,
      containsNoStore INTEGER NOT NULL,
      stickerPackId   TEXT,
      stickerHashKey  TEXT,
      pseudoMessageType INTEGER,
      pseudoMessageData TEXT,
      CONSTRAINT fk_quote FOREIGN KEY (quote_id) REFERENCES $messagesTable (id)
      CONSTRAINT fk_file_metadata FOREIGN KEY (file_metadata_id) REFERENCES $fileMetadataTable (id)
    )''',
  );

  await db.execute(
    'INSERT INTO ${messagesTable}_new SELECT id, sender, body, timestamp, sid, conversationJid, isFileUploadNotification, encrypted, errorType, warningType, received, displayed, acked, originId, quote_id, file_metadata_id, isDownloading, isUploading, isRetracted, isEdited, reactions, containsNoStore, stickerPackId, stickerHashKey, pseudoMessageType, pseudoMessageData FROM $messagesTable',
  );
  await db.execute('DROP TABLE $messagesTable');
  await db.execute(
    'ALTER TABLE ${messagesTable}_new RENAME TO $messagesTable;',
  );
}
