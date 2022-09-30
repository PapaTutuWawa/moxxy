import 'dart:convert';
import 'package:meta/meta.dart';

@immutable
class MediaFileLocation {

  const MediaFileLocation(this.url, this.encryptionScheme, this.key, this.iv);
  final String url;
  final String? encryptionScheme;
  final List<int>? key;
  final List<int>? iv;

  String? get keyBase64 {
    if (key != null) return base64Encode(key!);

    return null;
  }

  String? get ivBase64 {
    if (iv != null) return base64Encode(iv!);

    return null;
  }

  @override
  int get hashCode => url.hashCode ^ key.hashCode ^ iv.hashCode;

  @override
  bool operator==(Object other) {
    return other is MediaFileLocation && url == other.url && key == other.key && iv == other.iv;
  }
}
