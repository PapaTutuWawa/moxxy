import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;

class StickersService {
  Map<String, StickerPack> _stickerPacks = {};

  Future<StickerPack?> getStickerPackById(String id) async {
    if (_stickerPacks.containsKey(id)) return _stickerPacks[id];

    final pack = await GetIt.I.get<DatabaseService>().getStickerPackById(id);
    if (pack == null) return null;

    _stickerPacks[id] = pack;
    return _stickerPacks[id];
  }

  Future<Sticker?> getStickerBySFS(String? packId, moxxmpp.StatelessFileSharingData? sfs) async {
    if (packId == null || sfs == null) return null;

    final pack = await getStickerPackById(packId);
    if (pack == null) return null;

    return firstWhereOrNull<Sticker>(
      pack.stickers,
      (sticker) {
        for (final algo in sfs.metadata.hashes.keys) {
          if (sticker.hashes[algo] == sfs.metadata.hashes[algo]) {
            return true;
          }
        }

        return false;
      },
    );
  }
  
  // TODO(PapaTutuWawa): Implement
  //Future<void> addStickerPackFromData();
}
