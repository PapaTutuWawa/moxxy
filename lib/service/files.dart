import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/cryptography/cryptography.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// A class for returning whether a file metadata element was just created or retrieved.
class FileMetadataWrapper {
  FileMetadataWrapper(
    this.fileMetadata,
    this.retrieved,
  );

  /// The file metadata.
  FileMetadata fileMetadata;

  /// Indicates whether the file metadata already exists (true) or
  /// if it has been created (false).
  bool retrieved;
}

/// Returns the strongest hash from [map], if [map] is not null. If no known hash is found
/// or [map] is null, returns null.
String? getStrongestHashFromMap(Map<String, String>? map) {
  if (map == null) {
    return null;
  }

  return map['blake2b-512'] ??
      map['blake2b-256'] ??
      map['sha3-512'] ??
      map['sha3-256'] ??
      map['sha-512'] ??
      map['sha-256'];
}

/// Calculates the path for a given file with filename [filename] and the optional
/// plaintext hashes [hashes]. If the base directory for the file does not exist, then it
/// will be created.
Future<String> computeCachedPathForFile(
  String filename,
  Map<String, String>? hashes,
) async {
  final basePath = path.join(
    (await getApplicationDocumentsDirectory()).path,
    'media',
  );
  final baseDir = Directory(basePath);

  if (!baseDir.existsSync()) {
    await baseDir.create(recursive: true);
  }

  // Keep the extension of the file. Otherwise Android will be really confused
  // as to what it should open the file with.
  final ext = path.extension(filename);
  final hash = getStrongestHashFromMap(hashes)?.replaceAll('/', '_');
  return path.join(
    basePath,
    hash != null
        ? '$hash.$ext'
        : '$filename.${DateTime.now().millisecondsSinceEpoch}.$ext',
  );
}

class FilesService {
  // Logging.
  final Logger _log = Logger('FilesService');

  Future<void> createMetadataHashEntries(
    Map<String, String> plaintextHashes,
    String metadataId,
  ) async {
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
    final hash = metadata.plaintextHashes?['SHA-256'] ??
        await GetIt.I
            .get<CryptographyService>()
            .hashFile(metadata.path!, HashFunction.sha256);
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

  Future<FileMetadata?> getFileMetadataFromHash(
    Map<String, String>? plaintextHashes,
  ) async {
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

  /// Create a FileMetadata entry if we do not know the plaintext hashes described in
  /// [location].
  /// If we know of at least one hash, return that FileMetadata element.
  ///
  /// If [createHashPointers] is true and we have to create a new FileMetadata element,
  /// then also create the hash pointers, if plaintext hashes are specified. If no
  /// plaintext hashes are specified or [createHashPointers] is false, no pointers will be
  /// created.
  Future<FileMetadataWrapper> createFileMetadataIfRequired(
    MediaFileLocation location,
    String? mimeType,
    int? size,
    Size? dimensions,
    String? thubnailType,
    String? thumbnailData, {
    bool createHashPointers = true,
    String? path,
  }) async {
    if (location.plaintextHashes?.isNotEmpty ?? false) {
      final result = await getFileMetadataFromHash(location.plaintextHashes);
      if (result != null) {
        _log.finest('Not creating new metadata as we found the hash');
        return FileMetadataWrapper(
          result,
          true,
        );
      }
    }

    final db = GetIt.I.get<DatabaseService>().database;
    final fm = FileMetadata(
      getStrongestHashFromMap(location.plaintextHashes) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      path,
      location.urls,
      mimeType,
      size,
      thubnailType,
      thumbnailData,
      dimensions?.width.toInt(),
      dimensions?.height.toInt(),
      location.plaintextHashes,
      location.key != null ? base64Encode(location.key!) : null,
      location.iv != null ? base64Encode(location.iv!) : null,
      location.encryptionScheme,
      location.ciphertextHashes,
      location.filename,
    );
    await db.insert(fileMetadataTable, fm.toDatabaseJson());

    if ((location.plaintextHashes?.isNotEmpty ?? false) && createHashPointers) {
      await createMetadataHashEntries(
        location.plaintextHashes!,
        fm.id,
      );
    }

    return FileMetadataWrapper(
      fm,
      false,
    );
  }

  Future<void> removeFileMetadata(String id) async {
    await GetIt.I.get<DatabaseService>().database.delete(
      fileMetadataTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<FileMetadata> updateFileMetadata(
    String id, {
    Object? path = notSpecified,
    int? size,
    String? encryptionScheme,
    String? encryptionKey,
    String? encryptionIv,
    List<String>? sourceUrls,
    int? width,
    int? height,
    String? mimeType,
    Map<String, String>? plaintextHashes,
    Map<String, String>? ciphertextHashes,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final m = <String, dynamic>{};

    if (path != notSpecified) {
      m['path'] = path as String?;
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
    if (sourceUrls != null) {
      m['sourceUrl'] = jsonEncode(sourceUrls);
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
    if (plaintextHashes != null) {
      m['plaintextHashes'] = jsonEncode(plaintextHashes);
    }
    if (ciphertextHashes != null) {
      m['cipherTextHashes'] = jsonEncode(ciphertextHashes);
    }

    final result = await db.updateAndReturn(
      fileMetadataTable,
      m,
      where: 'id = ?',
      whereArgs: [id],
    );

    return FileMetadata.fromDatabaseJson(result);
  }

  /// Removes the file metadata described by [metadata] if it is referenced by exactly 0
  /// messages and no stickers use this file. If the file is referenced by > 1 messages
  /// or a sticker, does nothing.
  Future<void> removeFileIfNotReferenced(FileMetadata metadata) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final messagesCount =
        await db.count(
          messagesTable,
          'file_metadata_id = ?',
          [metadata.id],
        );
    final stickersCount =
        await db.count(
          stickersTable,
          'file_metadata_id = ?',
          [metadata.id],
        );

    if (messagesCount == 0 && stickersCount == 0) {
      _log.finest(
        'Removing file metadata as no stickers and no messages reference it',
      );
      await removeFileMetadata(metadata.id);

      // Only remove the file if we have a path
      if (metadata.path != null) {
        try {
          await File(metadata.path!).delete();
        } catch (ex) {
          _log.warning('Failed to remove file ${metadata.path!}: $ex');
        }
      } else {
        _log.info('Not removing file as there is no path associated with it');
      }
    } else {
      _log.info(
        'Not removing file as $messagesCount messages and $stickersCount stickers reference this file',
      );
    }
  }
}
