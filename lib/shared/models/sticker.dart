import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/helpers.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:path/path.dart' as path;

part 'sticker.freezed.dart';
part 'sticker.g.dart';

@freezed
class Sticker with _$Sticker {
  factory Sticker(
    String id,
    String stickerPackId,
    String desc,
    Map<String, String> suggests,
    FileMetadata fileMetadata,
  ) = _Sticker;

  const Sticker._();

  /// Moxxmpp
  factory Sticker.fromMoxxmpp(moxxmpp.Sticker sticker, String stickerPackId) {
    final hashKey = getStickerHashKey(sticker.metadata.hashes);
    final firstUrl = (sticker.sources.firstWhereOrNull((src) => src is moxxmpp.StatelessFileSharingUrlSource)! as moxxmpp.StatelessFileSharingUrlSource).url;
    return Sticker(
      hashKey,
      stickerPackId,
      sticker.metadata.desc!,
      sticker.suggests,
      FileMetadata(
        hashKey,
        null,
        sticker.sources.whereType<moxxmpp.StatelessFileSharingUrlSource>().map((src) => src.url).toList(),
        sticker.metadata.mediaType,
        sticker.metadata.size,
        null,
        null,
        sticker.metadata.width,
        sticker.metadata.height,
        sticker.metadata.hashes,
        null,
        null,
        null,
        null,
        sticker.metadata.name ?? path.basename(firstUrl),
      ),
    );
  }

  /// JSON
  factory Sticker.fromJson(Map<String, dynamic> json) =>
      _$StickerFromJson(json);

  factory Sticker.fromDatabaseJson(Map<String, dynamic> json, FileMetadata fileMetadata) {
    return Sticker.fromJson({
      ...json,
      'suggests':
          (jsonDecode(json['suggests']! as String) as Map<dynamic, dynamic>)
              .cast<String, String>(),
      'fileMetadata': fileMetadata.toJson(),
    });
  }

  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('fileMetadata');

    return {
      ...map,
      'suggests': jsonEncode(suggests),
      'file_metadata_id': fileMetadata.id,
    };
  }

  moxxmpp.Sticker toMoxxmpp() => moxxmpp.Sticker(
        moxxmpp.FileMetadataData(
          mediaType: fileMetadata.mimeType,
          desc: desc,
          size: fileMetadata.size,
          width: fileMetadata.width,
          height: fileMetadata.height,
          thumbnails: [],
          hashes: fileMetadata.plaintextHashes,
        ),
        // ignore: unnecessary_lambdas
        fileMetadata.sourceUrls!.map((src) => moxxmpp.StatelessFileSharingUrlSource(src)).toList(),
        suggests,
      );

  /// True, if the sticker is backed by an image with MIME type image/*.
  bool get isImage => fileMetadata.mimeType?.startsWith('image/') ?? false;
}
