import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/database/helpers.dart';
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
    bool restricted,
    bool local,

    /// The timestamp (milliseconds since epoch) when the sticker pack was added
    int addedTimestamp,

    /// The size in bytes
    int size,
  ) = _StickerPack;

  const StickerPack._();

  /// Moxxmpp
  factory StickerPack.fromMoxxmpp(moxxmpp.StickerPack pack, bool local) =>
      StickerPack(
        pack.id,
        pack.name,
        pack.summary,
        pack.stickers
            .map((sticker) => Sticker.fromMoxxmpp(sticker, pack.id))
            .toList(),
        pack.hashAlgorithm.toName(),
        pack.hashValue,
        pack.restricted,
        local,
        0,
        0,
      );

  /// JSON
  factory StickerPack.fromJson(Map<String, dynamic> json) =>
      _$StickerPackFromJson(json);

  factory StickerPack.fromDatabaseJson(
    Map<String, dynamic> json,
    List<Sticker> stickers,
  ) {
    final pack = StickerPack.fromJson({
      ...json,
      'local': true,
      'restricted': intToBool(json['restricted']! as int),
      'stickers': <Sticker>[],
      'size': 0,
    });

    return pack.copyWith(stickers: stickers);
  }

  Map<String, dynamic> toDatabaseJson() {
    final json = toJson()
      ..remove('local')
      ..remove('stickers')
      ..remove('size');

    return {
      ...json,
      'restricted': boolToInt(restricted),
    };
  }

  moxxmpp.StickerPack toMoxxmpp() => moxxmpp.StickerPack(
        id,
        name,
        description,
        moxxmpp.HashFunction.fromName(hashAlgorithm),
        hashValue,
        stickers.map((sticker) => sticker.toMoxxmpp()).toList(),
        restricted,
      );
}
