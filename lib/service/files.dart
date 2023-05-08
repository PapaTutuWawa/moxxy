import 'dart:convert';
import 'dart:ui';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/cryptography/cryptography.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';

String? getStrongestHashFromMap(Map<String, String>? map) {
  if (map == null) {
    return null;
  }

  return map['SHA-512'] ?? map['SHA-256'];
}

class FilesService {
  // Logging.
  final Logger _log = Logger('FilesService');

  Future<void> createMetadataHashEntries(Map<String, String> plaintextHashes, String metadataId) async {
    final db = GetIt.I.get<DatabaseService>().database;
    for (final hash in plaintextHashes.entries) {
      await db.insert(
        fileMetadataHashesTable,
        {
          'algorithm': hash.key,
          'value': hash.value,
          'id': metadataId,
        },
      );
    }
  }
  
  Future<FileMetadata?> getFileMetadataFromFile(FileMetadata metadata) async {
    final hash = metadata.plaintextHashes?['SHA-256'] ?? await GetIt.I.get<CryptographyService>().hashFile(metadata.path!, HashFunction.sha256);
    final fm = await getFileMetadataFromHash({
      'SHA-256': hash,
    });

    if (fm != null) {
      return fm;
    }

    final result = await GetIt.I.get<DatabaseService>().addFileMetadataFromData(
      metadata.copyWith(
        plaintextHashes: {
          ...metadata.plaintextHashes ?? {},
          'SHA-256': hash,
        },
      ),
    );
    await createMetadataHashEntries(result.plaintextHashes!, result.id);
    return result;
  }
  
  Future<FileMetadata?> getFileMetadataFromHash(Map<String, String>? plaintextHashes) async {
    if (plaintextHashes?.isEmpty ?? true) {
      return null;
    }

    final db = GetIt.I.get<DatabaseService>().database;
    final values = List<String>.empty(growable: true);
    final query = plaintextHashes!.entries.map((entry) {
      values
        ..add(entry.key)
        ..add(entry.value);
      return '(algorithm = ? AND value = ?)';
    }).join(' OR ');
    final hashes = await db.query(
      fileMetadataHashesTable,
      where: query,
      whereArgs: values,
      limit: 1,
    );
    if (hashes.isEmpty) {
      return null;
    }

    final result = await db.query(
      fileMetadataTable,
      where: 'id = ?',
      whereArgs: [hashes[0]['id']! as String],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }

    return FileMetadata.fromDatabaseJson(result[0]);
  }

  Future<FileMetadata> createFileMetadataIfRequired(
    MediaFileLocation location,
    String? mimeType,
    int? size,
    Size? dimensions,
    String? thubnailType,
    String? thumbnailData,
  ) async {
    if (location.plaintextHashes?.isNotEmpty ?? false) {
      final result = await getFileMetadataFromHash(location.plaintextHashes);
      if (result != null) {
        _log.finest('Not creating new metadata as we found the hash');
        return result;
      }
    }

    final db = GetIt.I.get<DatabaseService>().database;
    final fm = FileMetadata(
      getStrongestHashFromMap(location.plaintextHashes) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      null,
      location.url,
      mimeType,
      size,
      thubnailType,
      thumbnailData,
      dimensions?.width.toInt(),
      dimensions?.height.toInt(),
      location.plaintextHashes,
      location.key != null ?
        base64Encode(location.key!) : null,
      location.iv != null ?
        base64Encode(location.iv!) : null,
      location.encryptionScheme,
      location.ciphertextHashes,
      location.filename,
    );
    await db.insert(fileMetadataTable, fm.toDatabaseJson());

    if (location.plaintextHashes?.isNotEmpty ?? false) {
      await createMetadataHashEntries(
        location.plaintextHashes!,
        fm.id,
      );
    }

    return fm;
  }

  Future<void> removeFileMetadata(String id) async {
    await GetIt.I.get<DatabaseService>().database.delete(
      fileMetadataTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<FileMetadata> updateFileMetadata(String id, {
      String? path,
      int? size,
      String? encryptionScheme,
      String? encryptionKey,
      String? encryptionIv,
      String? sourceUrl,
      int? width,
      int? height,
      String? mimeType,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final m = <String, dynamic>{};

    if (path != null) {
      m['path'] = path;
    }
    if (encryptionScheme != null) {
      m['encryptionScheme'] = encryptionScheme;
    }
    if (size != null) {
      m['size'] = size;
    }
    if (encryptionKey != null) {
      m['encryptionKey'] = encryptionKey;
    }
    if (encryptionIv != null) {
      m['encryptionIv'] = encryptionIv;
    }
    if (sourceUrl != null) {
      m['sourceUrl'] = sourceUrl;
    }
    if (width != null) {
      m['width'] = width;
    }
    if (height != null) {
      m['height'] = height;
    }
    if (mimeType != null) {
      m['mimeType'] = mimeType;
    }

    final result = await db.updateAndReturn(
      fileMetadataTable,
      m,
      where: 'id = ?',
      whereArgs: [id],
    );

    return FileMetadata.fromDatabaseJson(result);
  }
}
