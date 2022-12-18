import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/xmpp.dart';
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

  Future<Sticker?> getStickerByHashKey(String packId, String hashKey) async {
    final pack = await getStickerPackById(packId);
    if (pack == null) return null;

    return firstWhereOrNull<Sticker>(
      pack.stickers,
      (sticker) => sticker.hashKey == hashKey,
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
  
  Future<void> removeStickerPack(String id) async {
    final pack = await getStickerPackById(id);
    assert(pack != null, 'The sticker pack must exist');

    // Delete the files
    final stickerPackPath = await getStickerPackPath(
      pack!.hashAlgorithm,
      pack.hashValue,
    );
    final stickerPackDir = Directory(stickerPackPath);
    if (stickerPackDir.existsSync()) {
      unawaited(
        stickerPackDir.delete(
          recursive: true,
        ),
      );
    }
    
    // Remove from the database
    await GetIt.I.get<DatabaseService>().removeStickerPackById(id);

    // Remove from the cache
    _stickerPacks.remove(id);
    
    // Retract from PubSub
    final state = await GetIt.I.get<XmppService>().getXmppState();
    final result = await GetIt.I.get<moxxmpp.XmppConnection>()
      .getManagerById<moxxmpp.StickersManager>(moxxmpp.stickersManager)!
      .retractStickerPack(moxxmpp.JID.fromString(state.jid!), id);

    if (result.isType<moxxmpp.PubSubError>()) {
      _log.severe('Failed to retract sticker pack');
    }
  }
  
  Future<void> _publishStickerPack(moxxmpp.StickerPack pack) async {
    final state = await GetIt.I.get<XmppService>().getXmppState();
    final result = await GetIt.I.get<moxxmpp.XmppConnection>()
      .getManagerById<moxxmpp.StickersManager>(moxxmpp.stickersManager)!
      .publishStickerPack(moxxmpp.JID.fromString(state.jid!), pack);

    if (result.isType<moxxmpp.PubSubError>()) {
      _log.severe('Failed to publish sticker pack');
    }
  }

  /// Returns the path to the sticker pack with hash algorithm [algo] and hash [hash].
  /// Ensures that the directory exists before returning.
  Future<String> _getStickerPackPath(String algo, String hash) async {
    final stickerDirPath = await getStickerPackPath(algo, hash);
    final stickerDir = Directory(stickerDirPath);
    if (!stickerDir.existsSync()) await stickerDir.create(recursive: true);

    return stickerDirPath;
  }
  
  Future<StickerPack?> installFromPubSub(StickerPack remotePack) async {
    assert(!remotePack.local, 'Sticker pack must be remote');

    final stickerPackPath = await _getStickerPackPath(
      remotePack.hashAlgorithm,
      remotePack.hashValue,
    );

    var success = true;
    final stickers = List<Sticker>.from(remotePack.stickers);
    for (var i = 0; i < stickers.length; i++) {
      final sticker = stickers[i];
      final stickerPath = p.join(
        stickerPackPath,
        sticker.hashes.values.first,
      );
      dio.Response<dynamic>? response;
      try {
        response = await dio.Dio().downloadUri(
          Uri.parse(sticker.urlSources.first),
          stickerPath,
        );
      } on dio.DioError catch(err) {
        _log.severe('Error downloading ${sticker.urlSources.first}: $err');
        success = false;
        break;
      }

      if (!isRequestOkay(response.statusCode)) {
        _log.severe('Request not okay: $response');
        break;
      }
      stickers[i] = sticker.copyWith(
        path: stickerPath,
        hashKey: getStickerHashKey(sticker.hashes),
      );
    } 

    if (!success) {
      _log.severe('Import failed');
      return null;
    }

    // Add the sticker pack to the database
    final db = GetIt.I.get<DatabaseService>();
    await db.addStickerPackFromData(remotePack);

    // Add the stickers to the database
    final stickersDb = List<Sticker>.empty(growable: true);
    for (final sticker in stickers) {
      stickersDb.add(
        await db.addStickerFromData(
          sticker.mediaType,
          sticker.desc,
          sticker.size,
          sticker.width,
          sticker.height,
          sticker.hashes,
          sticker.urlSources,
          sticker.path,
          remotePack.hashValue,
        ),
      );
    }

    // Publish but don't block
    unawaited(
      _publishStickerPack(
        moxxmpp.StickerPack(
          remotePack.id,
          remotePack.name,
          remotePack.description,
          moxxmpp.hashFunctionFromName(remotePack.hashAlgorithm),
          remotePack.hashValue,
          remotePack.stickers
            .map((sticker) => moxxmpp.Sticker(
              moxxmpp.FileMetadataData(
                mediaType: sticker.mediaType,
                desc: sticker.desc,
                size: sticker.size,
                width: sticker.width,
                height: sticker.height,
                thumbnails: [],
                hashes: sticker.hashes,
              ),
              sticker.urlSources
                // ignore: unnecessary_lambdas
                .map((src) => moxxmpp.StatelessFileSharingUrlSource(src))
                .toList(),
              // TODO(PapaTutuWawa): Store the suggests
              <String, String>{},
            ),).toList(),
          // TODO(PapaTutuWawa): Store this value
          false,
        ),
      ),
    );
    
    return remotePack.copyWith(
      stickers: stickersDb,
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
    final packRaw = moxxmpp.StickerPack.fromXML(
      '',
      node,
      hashAvailable: false,
    );

    if (packRaw.restricted) {
      _log.severe('Invalid sticker pack: Restricted');
      return null;
    }
    
    for (final sticker in packRaw.stickers) {
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

    final pack = packRaw.copyWithId(
      moxxmpp.HashFunction.sha256,
      await packRaw.getHash(moxxmpp.HashFunction.sha256),
    );
    _log.finest('New sticker pack identifier: sha256:${pack.id}');

    
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
      true,
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

    final stickerPackWithStickers = stickerPack.copyWith(
      stickers: stickers,
    );

    // Add it to the cache
    _stickerPacks[pack.hashValue] = stickerPackWithStickers;

    _log.info('Sticker pack ${stickerPack.id} successfully added to the database');

    // Publish but don't block
    unawaited(_publishStickerPack(pack));
    return stickerPackWithStickers;
  }
}
