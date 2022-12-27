import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/helpers.dart';

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

  /// Moxxmpp
  factory Sticker.fromMoxxmpp(moxxmpp.Sticker sticker, String stickerPackId) => Sticker(
    getStickerHashKey(sticker.metadata.hashes),
    sticker.metadata.mediaType!,
    sticker.metadata.desc!,
    sticker.metadata.size!,
    sticker.metadata.width,
    sticker.metadata.height,
    sticker.metadata.hashes,
    sticker.sources
      .whereType<moxxmpp.StatelessFileSharingUrlSource>()
      .map((src) => src.url)
      .toList(),
    '',
    stickerPackId,
    sticker.suggests,
  );
  
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

  moxxmpp.Sticker toMoxxmpp() => moxxmpp.Sticker(
    moxxmpp.FileMetadataData(
      mediaType: mediaType,
      desc: desc,
      size: size,
      width: width,
      height: height,
      thumbnails: [],
      hashes: hashes,
    ),
    urlSources
      // ignore: unnecessary_lambdas
      .map((src) => moxxmpp.StatelessFileSharingUrlSource(src))
      .toList(),
    suggests,
  );

  /// True, if the sticker is backed by an image with MIME type image/*.
  bool get isImage => mediaType.startsWith('image/');
}
