import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/files.dart';
import 'package:moxxyv2/service/httpfiletransfer/client.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:path/path.dart' as p;

class StickersService {
  final Map<String, StickerPack> _stickerPacks = {};
  final Logger _log = Logger('StickersService');

  Future<StickerPack?> getStickerPackById(String id) async {
    if (_stickerPacks.containsKey(id)) return _stickerPacks[id];

    final db = GetIt.I.get<DatabaseService>().database;
    final rawPack = await db.query(
      stickerPacksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rawPack.isEmpty) return null;

    final rawStickers = await db.rawQuery(
      '''
SELECT
  sticker.*,
  fm.id AS fm_id,
  fm.path AS fm_path,
  fm.sourceUrl AS fm_sourceUrl,
  fm.mimeType AS fm_mimeType,
  fm.thumbnailType AS fm_thumbnailType,
  fm.thumbnailData AS fm_thumbnailData,
  fm.width AS fm_width,
  fm.height AS fm_height,
  fm.plaintextHashes AS fm_plaintextHashes,
  fm.encryptionKey AS fm_encryptionKey,
  fm.encryptionIv AS fm_encryptionIv,
  fm.encryptionScheme AS fm_encryptionScheme,
  fm.cipherTextHashes AS fm_cipherTextHashes,
  fm.filename AS fm_filename,
  fm.size AS fm_size
FROM (SELECT * FROM $stickersTable WHERE stickerPackId = ?) AS sticker
  JOIN $fileMetadataTable fm ON sticker.file_metadata_id = fm.id;
      ''',
    );

    _stickerPacks[id] = StickerPack.fromDatabaseJson(
      rawPack.first,
      rawStickers.map((sticker) {
        return Sticker.fromDatabaseJson(
          sticker,
          FileMetadata.fromDatabaseJson(sticker),
        );
      }).toList(),
    );

    return _stickerPacks[id]!;
  }

  Future<List<StickerPack>> getStickerPacks() async {
    if (_stickerPacks.isEmpty) {
      final rawPackIds = await GetIt.I.get<DatabaseService>().database.query(
        stickerPacksTable,
        columns: ['id'],
      );
      for (final rawPack in rawPackIds) {
        final id = rawPack['id']! as String;
        await getStickerPackById(id);
      }
    }

    return _stickerPacks.values.toList();
  }

  Future<void> removeStickerPack(String id) async {
    final pack = await getStickerPackById(id);
    assert(pack != null, 'The sticker pack must exist');

    // Delete the files
    for (final sticker in pack!.stickers) {
      if (sticker.fileMetadata.path == null) {
        continue;
      }

      await GetIt.I.get<FilesService>().updateFileMetadata(
        sticker.fileMetadata.id,
        path: null,
      );
      final file = File(sticker.fileMetadata.path!);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    // Remove from the database
    await GetIt.I.get<DatabaseService>().database.delete(
      stickerPacksTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Remove from the cache
    _stickerPacks.remove(id);

    // Retract from PubSub
    final state = await GetIt.I.get<XmppStateService>().getXmppState();
    final result = await GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.StickersManager>(moxxmpp.stickersManager)!
        .retractStickerPack(moxxmpp.JID.fromString(state.jid!), id);

    if (result.isType<moxxmpp.PubSubError>()) {
      _log.severe('Failed to retract sticker pack');
    }
  }

  Future<void> _publishStickerPack(moxxmpp.StickerPack pack) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    final state = await GetIt.I.get<XmppStateService>().getXmppState();
    final result = await GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.StickersManager>(moxxmpp.stickersManager)!
        .publishStickerPack(
          moxxmpp.JID.fromString(state.jid!),
          pack,
          accessModel: prefs.isStickersNodePublic ? 'open' : null,
        );

    if (result.isType<moxxmpp.PubSubError>()) {
      _log.severe('Failed to publish sticker pack');
    }
  }

  Future<void> importFromPubSubWithEvent(
    moxxmpp.JID jid,
    String stickerPackId,
  ) async {
    final stickerPack = await importFromPubSub(jid, stickerPackId);
    if (stickerPack == null) return;

    sendEvent(
      StickerPackAddedEvent(
        stickerPack: stickerPack,
      ),
    );
  }

  /// Takes the jid of the host [jid] and the id [stickerPackId] of the sticker pack
  /// and tries to fetch and install it, including publishing on our own PubSub node.
  ///
  /// On success, returns the installed StickerPack. On failure, returns null.
  Future<StickerPack?> importFromPubSub(
    moxxmpp.JID jid,
    String stickerPackId,
  ) async {
    final result = await GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.StickersManager>(moxxmpp.stickersManager)!
        .fetchStickerPack(jid.toBare(), stickerPackId);

    if (result.isType<moxxmpp.PubSubError>()) {
      _log.warning('Failed to fetch sticker pack $jid:$stickerPackId');
      return null;
    }

    final stickerPackRaw = StickerPack.fromMoxxmpp(
      result.get<moxxmpp.StickerPack>(),
      false,
    );

    // Install the sticker pack
    return installFromPubSub(stickerPackRaw);
  }

  Future<void> _addStickerPackFromData(StickerPack pack) async {
    await GetIt.I.get<DatabaseService>().database.insert(
      stickerPacksTable,
      pack.toDatabaseJson(),
    );
  }

  
  Future<Sticker> _addStickerFromData(String id, String stickerPackId, String desc, Map<String, String> suggests, FileMetadata fileMetadata) async {
    final s = Sticker(
      id,
      stickerPackId,
      desc,
      suggests,
      fileMetadata,
    );

    await GetIt.I.get<DatabaseService>().database.insert(
      stickersTable,
      s.toDatabaseJson(),
    );
    return s;
  }
  
  Future<StickerPack?> installFromPubSub(StickerPack remotePack) async {
    assert(!remotePack.local, 'Sticker pack must be remote');

    var success = true;
    final stickers = List<Sticker>.from(remotePack.stickers);
    for (var i = 0; i < stickers.length; i++) {
      final sticker = stickers[i];
      final stickerPath = await computeCachedPathForFile(
        sticker.fileMetadata.filename,
        sticker.fileMetadata.plaintextHashes,
      );

      // Get file metadata
      final fileMetadataRaw = await GetIt.I.get<FilesService>().createFileMetadataIfRequired(
        MediaFileLocation(
          sticker.fileMetadata.sourceUrls!,
          p.basename(stickerPath),
          null,
          null,
          null,
          sticker.fileMetadata.plaintextHashes,
          null,
          sticker.fileMetadata.size,
        ),
        sticker.fileMetadata.mimeType, 
        sticker.fileMetadata.size,
        sticker.fileMetadata.width != null && sticker.fileMetadata.height != null
          ? Size(sticker.fileMetadata.width!.toDouble(), sticker.fileMetadata.height!.toDouble())
          : null,
        // TODO(Unknown): Maybe consider the thumbnails one day
        null,
        null,
        path: stickerPath,
      );

      if (!fileMetadataRaw.retrieved) {
        final downloadStatusCode = await downloadFile(
          Uri.parse(sticker.fileMetadata.sourceUrls!.first),
          stickerPath,
          (_, __) {},
        );

        if (!isRequestOkay(downloadStatusCode)) {
          _log.severe('Request not okay: $downloadStatusCode');
          success = false;
          break;
        }
      }

      stickers[i] = await _addStickerFromData( 
        getStrongestHashFromMap(sticker.fileMetadata.plaintextHashes) ?? DateTime.now().millisecondsSinceEpoch.toString(),
        remotePack.hashValue,
        sticker.desc,
        sticker.suggests,
        fileMetadataRaw.fileMetadata,
      );
    }

    if (!success) {
      _log.severe('Import failed');
      return null;
    }

    // Add the sticker pack to the database
    await _addStickerPackFromData(remotePack);

    // Publish but don't block
    unawaited(
      _publishStickerPack(remotePack.toMoxxmpp()),
    );

    return remotePack.copyWith(
      stickers: stickers,
      local: true,
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

    moxxmpp.StickerPack packRaw;
    try {
      final content = utf8.decode(metadata.content as List<int>);
      final node = moxxmpp.XMLNode.fromString(content);
      packRaw = moxxmpp.StickerPack.fromXML(
        '',
        node,
        hashAvailable: false,
      );
    } catch (ex) {
      _log.severe('Invalid sticker pack description: $ex');
      return null;
    }

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
        _log.severe(
          'Invalid sticker pack: $filename does not exist in archive',
        );
        return null;
      }
    }

    final pack = packRaw.copyWithId(
      moxxmpp.HashFunction.sha256,
      await packRaw.getHash(moxxmpp.HashFunction.sha256),
    );
    _log.finest('New sticker pack identifier: sha256:${pack.id}');

    if (await getStickerPackById(pack.id) != null) {
      _log.severe('Invalid sticker pack: Already exists');
      return null;
    }

    final stickerDirPath = await getStickerPackPath(
      pack.hashAlgorithm.toName(),
      pack.hashValue,
    );
    final stickerDir = Directory(stickerDirPath);
    if (!stickerDir.existsSync()) await stickerDir.create(recursive: true);

    // Create the sticker pack first
    final stickerPack = StickerPack(
      pack.hashValue,
      pack.name,
      pack.summary,
      [],
      pack.hashAlgorithm.toName(),
      pack.hashValue,
      pack.restricted,
      true,
    );
    await _addStickerPackFromData(stickerPack);

    // Add all stickers
    final stickers = List<Sticker>.empty(growable: true);
    for (final sticker in pack.stickers) {
      // Get the "path" to the sticker
      final stickerPath = await computeCachedPathForFile(
        sticker.metadata.name!,
        sticker.metadata.hashes,
      );

      // Get metadata
      final urlSources = sticker.sources.whereType<moxxmpp.StatelessFileSharingUrlSource>().map((src) => src.url).toList();
      final fileMetadataRaw = await GetIt.I.get<FilesService>().createFileMetadataIfRequired(
        MediaFileLocation(
          urlSources,
          p.basename(stickerPath),
          null,
          null,
          null,
          sticker.metadata.hashes,
          null,
          sticker.metadata.size,
        ),
        sticker.metadata.mediaType,
        sticker.metadata.size,
        sticker.metadata.width != null && sticker.metadata.height != null
          ? Size(sticker.metadata.width!.toDouble(), sticker.metadata.height!.toDouble())
          : null,
        // TODO(Unknown): Maybe consider the thumbnails one day
        null,
        null,
        path: stickerPath,
      );

      // Only copy the sticker to storage if we don't already have it
      if (!fileMetadataRaw.retrieved) {
        final stickerFile = archive.findFile(sticker.metadata.name!)!;
        await File(stickerPath).writeAsBytes(
          stickerFile.content as List<int>,
        );
      }

      stickers.add(
        await _addStickerFromData(
          getStrongestHashFromMap(sticker.metadata.hashes) ?? DateTime.now().millisecondsSinceEpoch.toString(),
          pack.hashValue,
          sticker.metadata.desc!,
          sticker.suggests,
          fileMetadataRaw.fileMetadata,
        ),
      );
    }

    final stickerPackWithStickers = stickerPack.copyWith(
      stickers: stickers,
    );

    // Add it to the cache
    _stickerPacks[pack.hashValue] = stickerPackWithStickers;

    _log.info(
      'Sticker pack ${stickerPack.id} successfully added to the database',
    );

    // Publish but don't block
    unawaited(_publishStickerPack(pack));
    return stickerPackWithStickers;
  }
}
