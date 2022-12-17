import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:path/path.dart' as p;

class StickersService {
  final Map<String, StickerPack> _stickerPacks = {};
  final Logger _log = Logger('StickersService');

  Future<StickerPack?> getStickerPackById(String id) async {
    if (_stickerPacks.containsKey(id)) return _stickerPacks[id];

    final pack = await GetIt.I.get<DatabaseService>().getStickerPackById(id);
    if (pack == null) return null;

    _stickerPacks[id] = pack;
    return _stickerPacks[id];
  }

  Future<Sticker?> getStickerById(String packId, int id) async {
    final pack = await getStickerPackById(packId);
    if (pack == null) return null;

    return firstWhereOrNull<Sticker>(
      pack.stickers,
      (sticker) => sticker.id == id,
    );
  }
  
  Future<List<StickerPack>> getStickerPacks() async {
    if (_stickerPacks.isEmpty) {
      final packs = await GetIt.I.get<DatabaseService>().loadStickerPacks();
      for (final pack in packs) {
        _stickerPacks[pack.id] = pack;
      }
    }

    return _stickerPacks.values.toList();
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

  /// Imports a sticker pack from [path].
  /// The format is as follows:
  /// - The file MUST be an uncompressed tar archive
  /// - All files must be at the top level of the archive
  /// - A file 'urn.xmpp.stickers.0.xml' must exist and must contain only the <pack /> element
  /// - The File Metadata Elements must also contain a <name /> element
  ///   - The file referenced by the <name/> element must also exist on the archive's top level
  Future<StickerPack?> importFromFile(String path) async {
    final archiveBytes = await File(path).readAsBytes();
    final archive = TarDecoder().decodeBytes(archiveBytes);
    final metadata = archive.findFile('urn.xmpp.stickers.0.xml');
    if (metadata == null) {
      _log.severe('Invalid sticker pack: No metadata file');
      return null;
    }

    final content = utf8.decode(metadata.content as List<int>);
    final node = moxxmpp.XMLNode.fromString(content);
    final pack = moxxmpp.StickerPack.fromXML(
      // TODO(PapaTutuWawa): fix
      'EpRv28DHHzFrE4zd+xaNpVb4jbu4s74XtioExNjQzZ0=',
      node,
    );

    for (final sticker in pack.stickers) {
      final filename = sticker.metadata.name;
      if (filename == null) {
        _log.severe('Invalid sticker pack: One sticker has no <name/>');
        return null;
      }

      final stickerFile = archive.findFile(filename);
      if (stickerFile == null) {
        _log.severe('Invalid sticker pack: $filename does not exist in archive');
        return null;
      }
    }
    
    final stickerDirPath = await getStickerPackPath(
      pack.hashAlgorithm.toName(),
      pack.hashValue,
    );
    final stickerDir = Directory(stickerDirPath);
    if (!stickerDir.existsSync()) await stickerDir.create(recursive: true);

    final db = GetIt.I.get<DatabaseService>();

    // Create the sticker pack first
    final stickerPack = StickerPack(
      pack.hashValue,
      pack.name,
      pack.summary,
      [],
      pack.hashAlgorithm.toName(),
      pack.hashValue,
    );
    await db.addStickerPackFromData(stickerPack);

    // Add all stickers
    final stickers = List<Sticker>.empty(growable: true);
    for (final sticker in pack.stickers) {
      final filename = sticker.metadata.name!;
      final stickerFile = archive.findFile(filename)!;
      final stickerPath = p.join(stickerDirPath, filename);
      await File(stickerPath).writeAsBytes(
        stickerFile.content as List<int>,
      );

      stickers.add(
        await db.addStickerFromData(
          sticker.metadata.mediaType!,
          sticker.metadata.desc!,
          sticker.metadata.size!,
          null,
          null,
          sticker.metadata.hashes,
          sticker.sources
            .whereType<moxxmpp.StatelessFileSharingUrlSource>()
            .map((moxxmpp.StatelessFileSharingUrlSource source) => source.url)
            .toList(),
          stickerPath,
          pack.hashValue,
        ),
      );
    }

    // Add it to the cache
    _stickerPacks[pack.hashValue] = stickerPack;

    _log.info('Successfully added to the database');

    // TODO(PapaTutuWawa): Publish on PubSub
    return stickerPack;
  }
}
