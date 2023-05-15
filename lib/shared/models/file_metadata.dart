import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';

part 'file_metadata.freezed.dart';
part 'file_metadata.g.dart';

/// Wrapper for turning a map "Hash algorithm -> Hash value" [hashes] into a string
/// for storage in the database.
String serializeHashMap(Map<HashFunction, String> hashes) {
  final rawMap =
      hashes.map((key, value) => MapEntry<String, String>(key.toName(), value));
  return jsonEncode(rawMap);
}

/// Wrapper for turning a string [hashString] into a map "Hash algorithm -> Hash value".
Map<HashFunction, String> deserializeHashMap(String hashString) {
  final rawMap =
      (jsonDecode(hashString) as Map<dynamic, dynamic>).cast<String, String>();
  return rawMap.map(
    (key, value) =>
        MapEntry<HashFunction, String>(HashFunction.fromName(key), value),
  );
}

@freezed
class FileMetadata with _$FileMetadata {
  factory FileMetadata(
    /// A unique ID
    String id,

    /// The path where the file can be found.
    String? path,

    /// The source where the file came from.
    List<String>? sourceUrls,

    /// The MIME type of the media, if available.
    String? mimeType,

    /// The size in bytes of the file, if available.
    int? size,

    /// The type of thumbnail data we have, if [thumbnailData] is non-null.
    String? thumbnailType,

    /// String-encodable thumbnail data, like blurhash.
    String? thumbnailData,

    /// Media dimensions, if the media file has such attributes.
    int? width,
    int? height,

    /// A list of hashes for the original plaintext file.
    Map<HashFunction, String>? plaintextHashes,

    /// If non-null: The key the file was encrypted with.
    String? encryptionKey,

    /// If non-null: The IV used for encryption.
    String? encryptionIv,

    /// If non-null: The encryption method used for encrypting the file.
    String? encryptionScheme,

    /// A list of hashes for the encrypted file.
    Map<HashFunction, String>? ciphertextHashes,

    /// The actual filename of the file. If the filename was obfuscated, e.g. due
    /// to encryption, this should be the original filename.
    String filename,
  ) = _FileMetadata;
  const FileMetadata._();

  /// JSON
  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);

  factory FileMetadata.fromDatabaseJson(Map<String, dynamic> json) {
    final plaintextHashesRaw = json['plaintextHashes'] as String?;
    final plaintextHashes = plaintextHashesRaw != null
        ? deserializeHashMap(plaintextHashesRaw)
        : null;
    final ciphertextHashesRaw = json['ciphertextHashes'] as String?;
    final ciphertextHashes = ciphertextHashesRaw != null
        ? deserializeHashMap(ciphertextHashesRaw)
        : null;
    final sourceUrlsRaw = json['sourceUrls'] as String?;
    final sourceUrls = sourceUrlsRaw == null
        ? null
        : (jsonDecode(sourceUrlsRaw) as List<dynamic>).cast<String>();

    // Workaround for using enums as map keys
    final modifiedJson = Map<String, dynamic>.from(json)
      ..remove('plaintextHashes')
      ..remove('ciphertextHashes');
    return FileMetadata.fromJson({
      ...modifiedJson,
      'sourceUrls': sourceUrls,
    }).copyWith(
      plaintextHashes: plaintextHashes,
      ciphertextHashes: ciphertextHashes,
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('plaintextHashes')
      ..remove('ciphertextHashes')
      ..remove('sourceUrls');
    return {
      ...map,
      'plaintextHashes':
          plaintextHashes != null ? serializeHashMap(plaintextHashes!) : null,
      'ciphertextHashes':
          ciphertextHashes != null ? serializeHashMap(ciphertextHashes!) : null,
      'sourceUrls': sourceUrls != null ? jsonEncode(sourceUrls) : null,
    };
  }
}
