import 'dart:convert';
import 'package:meta/meta.dart';

@immutable
class MediaFileLocation {
  const MediaFileLocation(
    this.url,
    this.filename,
    this.encryptionScheme,
    this.key,
    this.iv,
    this.plaintextHashes,
    this.ciphertextHashes,
    this.size,
  );
  final String url;
  final String filename;
  final String? encryptionScheme;
  final List<int>? key;
  final List<int>? iv;
  final Map<String, String>? plaintextHashes;
  final Map<String, String>? ciphertextHashes;
  final int? size;

  String? get keyBase64 {
    if (key != null) return base64Encode(key!);

    return null;
  }

  String? get ivBase64 {
    if (iv != null) return base64Encode(iv!);

    return null;
  }

  @override
  int get hashCode =>
      url.hashCode ^
      filename.hashCode ^
      encryptionScheme.hashCode ^
      key.hashCode ^
      iv.hashCode ^
      plaintextHashes.hashCode ^
      ciphertextHashes.hashCode ^
      size.hashCode;

  @override
  bool operator ==(Object other) {
    // TODO(PapaTutuWawa): Compare the Maps
    return other is MediaFileLocation &&
        url == other.url &&
        filename == other.filename &&
        encryptionScheme == other.encryptionScheme &&
        key == other.key &&
        iv == other.iv &&
        size == other.size;
  }
}
