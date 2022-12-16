import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/shared/models/sticker.dart';

part 'sticker_pack.freezed.dart';
part 'sticker_pack.g.dart';

@freezed
class StickerPack with _$StickerPack {
  factory StickerPack(
    String id,
    String name,
    String description,
    List<Sticker> stickers,
    String hashAlgorithm,
    String hashValue,
  ) = _StickerPack;

  const StickerPack._();
  
  /// JSON
  factory StickerPack.fromJson(Map<String, dynamic> json) => _$StickerPackFromJson(json);

  factory StickerPack.fromDatabaseJson(Map<String, dynamic> json, List<Sticker> stickers) {
    final pack = StickerPack.fromJson({
      ...json,
      'stickers': <Sticker>[],
    });

    return pack.copyWith(stickers: stickers);
  }
  
  Map<String, dynamic> toDatabaseJson() {
    return toJson()
      ..remove('stickers');
  }  
}
