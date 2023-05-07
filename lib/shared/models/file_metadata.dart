import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_metadata.freezed.dart';
part 'file_metadata.g.dart';

@freezed
class FileMetadata with _$FileMetadata {
  factory FileMetadata(
    /// A unique ID
    int id,
    /// The path where the file can be found.
    String? path,
    /// The source where the file came from.
    String? sourceUrl,
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
    Map<String, String>? plaintextHashes,
    /// If non-null: The key the file was encrypted with.
    String? encryptionKey,
    /// If non-null: The IV used for encryption.
    String? encryptionIv,
    /// If non-null: The encryption method used for encrypting the file.
    String? encryptionScheme,
    /// A list of hashes for the encrypted file.
    Map<String, String>? ciphertextHashes,
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
    final plaintextHashes = plaintextHashesRaw == null ?
    null :
    Map<String, String>.fromEntries(
      plaintextHashesRaw.split(',').map((hash) {
          final parts = hash.split('-');
          return MapEntry<String, String>(
            parts.first,
            parts.last,
          );
      }),
    );
    final ciphertextHashesRaw = json['ciphertextHashes'] as String?;
    final ciphertextHashes = ciphertextHashesRaw == null ?
    null :
    Map<String, String>.fromEntries(
      ciphertextHashesRaw.split(',').map((hash) {
          final parts = hash.split('-');
          return MapEntry<String, String>(
            parts.first,
            parts.last,
          );
      }),
    );

    return FileMetadata.fromJson({
      ...json,
      'plaintextHashes': plaintextHashes,
      'ciphertextHashes': ciphertextHashes,
    });
  }
  
  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('plaintextHashes')
      ..remove('ciphertextHashes');
    return {
      ...map,
      'plaintextHashes': plaintextHashes?.entries.map((entry) => '${entry.key}-${entry.value}').join(';'),
      'ciphertextHashes': ciphertextHashes?.entries.map((entry) => '${entry.key}-${entry.value}').join(';'),
    };
  }
}
