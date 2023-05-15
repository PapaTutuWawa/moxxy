import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';

@immutable
class MediaFileLocation {
  const MediaFileLocation(
    this.urls,
    this.filename,
    this.encryptionScheme,
    this.key,
    this.iv,
    this.plaintextHashes,
    this.ciphertextHashes,
    this.size,
  );
  final List<String> urls;
  final String filename;
  final String? encryptionScheme;
  final List<int>? key;
  final List<int>? iv;
  final Map<HashFunction, String>? plaintextHashes;
  final Map<HashFunction, String>? ciphertextHashes;
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
      urls.hashCode ^
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
        filename == other.filename &&
        encryptionScheme == other.encryptionScheme &&
        key == other.key &&
        iv == other.iv &&
        size == other.size;
  }
}
