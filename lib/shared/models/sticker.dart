import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sticker.freezed.dart';
part 'sticker.g.dart';

@freezed
class Sticker with _$Sticker {
  factory Sticker(
    String hashKey,
    String mediaType,
    String desc,
    int size,
    int? width,
    int? height,
    /// Hash algorithm (algo attribute) -> Base64 encoded hash
    Map<String, String> hashes,
    List<String> urlSources,
    String path,
    String stickerPackId,
    Map<String, String> suggests,
  ) = _Sticker;

  const Sticker._();
  
  /// JSON
  factory Sticker.fromJson(Map<String, dynamic> json) => _$StickerFromJson(json);

  factory Sticker.fromDatabaseJson(Map<String, dynamic> json) {
    return Sticker.fromJson({
      ...json,
      'hashes': (jsonDecode(json['hashes']! as String) as Map<dynamic, dynamic>).cast<String, String>(),
      'urlSources': (jsonDecode(json['urlSources']! as String) as List<dynamic>).cast<String>(),
      'suggests': (jsonDecode(json['suggests']! as String) as Map<dynamic, dynamic>).cast<String, String>(),
    });
  }
  
  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('hashes')
      ..remove('urlSources')
      ..remove('suggests');

    return {
      ...map,
      'hashes': jsonEncode(hashes),
      'urlSources': jsonEncode(urlSources),
      'suggests': jsonEncode(suggests),
    };
  }
}
