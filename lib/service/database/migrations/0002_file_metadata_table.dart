import 'dart:convert';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV31ToV32(Database db) async {
  // Create the tracking table
  await db.execute('''
    CREATE TABLE $fileMetadataTable (
      id               INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      path             TEXT,
      sourceUrl        TEXT,
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
      id        INTEGER NOT NULL,
      CONSTRAINT f_primarykey PRIMARY KEY (algorithm, value),
      CONSTRAINT fk_id FOREIGN KEY (id) REFERENCES $fileMetadataTable (id)
        ON DELETE CASCADE
    )''');

  // Add the file_metadata_id column
  await db.execute('ALTER TABLE $messagesTable ADD COLUMN file_metadata_id INTEGER DEFAULT NULL;');
      
  // Migrate the media messages' attributes to new table
  final messages = await db.query(
    messagesTable,
    where: 'isMedia = ${boolToInt(true)}',
  );
  for (final message in messages) {
    // Do we know of a hash?
    int id;
    if (message['plaintextHashes'] != null) {
      // Plaintext hashes available (SFS)
      final plaintextHashes = (jsonDecode(message['plaintextHashes']! as String) as Map<dynamic, dynamic>).cast<String, String>();
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
          -1,
          message['mediaUrl'] as String?,
          message['srcUrl'] as String?,
          message['mediaType'] as String?,
          message['mediaSize'] as int?,
          message['thumbnailData'] != null ?
          'blurhash' :
          null,
          message['thumbnailData'] as String?,
          message['mediaWidth'] as int?,
          message['mediaHeight'] as int?,
          plaintextHashes,
          message['key'] as String?,
          message['iv'] as String?,
          message['encryptionScheme'] as String?,
          message['plaintextHashes'] == null ?
          null :
          (jsonDecode(message['ciphertextHashes']! as String) as Map<dynamic, dynamic>).cast<String, String>(),
          message['filename']! as String,
        );

        // Create the metadata
        final insertResult = await db.insertAndReturn(
          fileMetadataTable,
          metadata.toDatabaseJson(),
        );
        id = insertResult['id']! as int;
      } else {
        id = result[0]['id']! as int;
      }
    } else {
      // No plaintext hashes are available (OOB data)
      final metadata = FileMetadata(
        -1,
        message['mediaUrl'] as String?,
        message['srcUrl'] as String?,
        message['mediaType'] as String?,
        message['mediaSize'] as int?,
        message['thumbnailData'] != null ?
        'blurhash' :
        null,
        message['thumbnailData'] as String?,
        message['mediaWidth'] as int?,
        message['mediaHeight'] as int?,
        null,
        message['key'] as String?,
        message['iv'] as String?,
        message['encryptionScheme'] as String?,
        null,
        message['filename']! as String,
      );

      // Create the metadata
      final insertResult = await db.insertAndReturn(
        fileMetadataTable,
        metadata.toDatabaseJson(),
      );
      id = insertResult['id']! as int;
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
      file_metadata_id INTEGER,
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
  await db.execute('INSERT INTO ${messagesTable}_new SELECT * FROM $messagesTable');
  await db.execute('DROP TABLE $messagesTable');
  await db.execute(
    'ALTER TABLE ${messagesTable}_new RENAME TO $messagesTable;',
  );
}
