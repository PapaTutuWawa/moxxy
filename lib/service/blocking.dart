import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';

enum BlockPushType { block, unblock }

class BlocklistService {
  BlocklistService();
  List<String>? _blocklist;
  bool _requested = false;
  bool? _supported;
  final Logger _log = Logger('BlocklistService');

  Future<void> _removeBlocklistEntry(String jid, String accountJid) async {
    await GetIt.I.get<DatabaseService>().database.delete(
      blocklistTable,
      where: 'jid = ? AND accountJid = ?',
      whereArgs: [jid, accountJid],
    );
  }

  Future<void> _addBlocklistEntry(String jid, String accountJid) async {
    await GetIt.I.get<DatabaseService>().database.insert(
      blocklistTable,
      {
        'jid': jid,
        'accountJid': accountJid,
      },
    );
  }

  void onNewConnection() {
    // Invalidate the caches
    _blocklist = null;
    _requested = false;
    _supported = null;
  }

  Future<bool> _checkSupport() async {
    return _supported ??= await GetIt.I
        .get<XmppConnection>()
        .getManagerById<BlockingManager>(blockingManager)!
        .isSupported();
  }

  Future<void> _requestBlocklist() async {
    assert(
      _blocklist != null,
      'The blocklist must be loaded from the database before requesting',
    );

    // Check if blocking is supported
    if (!(await _checkSupport())) {
      _log.warning('Blocklist requested but server does not support it.');
      return;
    }

    final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
    final blocklist = await GetIt.I
        .get<XmppConnection>()
        .getManagerById<BlockingManager>(blockingManager)!
        .getBlocklist();

    // Diff the received blocklist with the cache
    final newItems = List<String>.empty(growable: true);
    final removedItems = List<String>.empty(growable: true);
    for (final item in blocklist) {
      if (!_blocklist!.contains(item)) {
        await _addBlocklistEntry(item, accountJid!);
        _blocklist!.add(item);
        newItems.add(item);
      }
    }

    // Diff the cache with the received blocklist
    for (final item in _blocklist!) {
      if (!blocklist.contains(item)) {
        await _removeBlocklistEntry(item, accountJid!);
        _blocklist!.remove(item);
        removedItems.add(item);
      }
    }

    _requested = true;

    // Trigger an UI event if we have anything to tell the UI
    if (newItems.isNotEmpty || removedItems.isNotEmpty) {
      sendEvent(
        BlocklistPushEvent(
          added: newItems,
          removed: removedItems,
        ),
      );
    }
  }

  /// Returns the blocklist from the database
  Future<List<String>> getBlocklist(String accountJid) async {
    if (_blocklist == null) {
      final blocklistRaw = await GetIt.I.get<DatabaseService>().database.query(
        blocklistTable,
        where: 'accountJid = ?',
        whereArgs: [accountJid],
      );
      _blocklist = blocklistRaw.map((m) => m['jid']! as String).toList();

      if (!_requested) {
        unawaited(_requestBlocklist());
      }

      return _blocklist!;
    }

    if (!_requested) {
      unawaited(_requestBlocklist());
    }

    return _blocklist!;
  }

  void onUnblockAllPush() {
    _blocklist = List<String>.empty(growable: true);
    sendEvent(
      BlocklistUnblockAllEvent(),
    );
  }

  Future<void> onBlocklistPush(BlockPushType type, List<String> items) async {
    // We will fetch it later when getBlocklist is called
    if (!_requested) return;

    final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
    final newBlocks = List<String>.empty(growable: true);
    final removedBlocks = List<String>.empty(growable: true);
    for (final item in items) {
      switch (type) {
        case BlockPushType.block:
          {
            if (_blocklist!.contains(item)) continue;
            _blocklist!.add(item);
            newBlocks.add(item);

            await _addBlocklistEntry(item, accountJid!);
          }
        case BlockPushType.unblock:
          {
            _blocklist!.removeWhere((i) => i == item);
            removedBlocks.add(item);

            await _removeBlocklistEntry(item, accountJid!);
          }
      }
    }

    sendEvent(
      BlocklistPushEvent(
        added: newBlocks,
        removed: removedBlocks,
      ),
    );
  }

  Future<bool> blockJid(String jid) async {
    // Check if blocking is supported
    if (!(await _checkSupport())) {
      _log.warning('Blocking $jid requested but server does not support it.');
      return false;
    }

    _blocklist!.add(jid);
    await _addBlocklistEntry(
      jid,
      (await GetIt.I.get<XmppStateService>().getAccountJid())!,
    );
    return GetIt.I
        .get<XmppConnection>()
        .getManagerById<BlockingManager>(blockingManager)!
        .block([jid]);
  }

  Future<bool> unblockJid(String jid) async {
    // Check if blocking is supported
    if (!(await _checkSupport())) {
      _log.warning('Unblocking $jid requested but server does not support it.');
      return false;
    }

    _blocklist!.remove(jid);
    await _removeBlocklistEntry(
      jid,
      (await GetIt.I.get<XmppStateService>().getAccountJid())!,
    );
    return GetIt.I
        .get<XmppConnection>()
        .getManagerById<BlockingManager>(blockingManager)!
        .unblock([jid]);
  }

  Future<bool> unblockAll() async {
    // Check if blocking is supported
    if (!(await _checkSupport())) {
      _log.warning(
        'Unblocking all JIDs requested but server does not support it.',
      );
      return false;
    }

    _blocklist!.clear();
    await GetIt.I.get<DatabaseService>().database.delete(
      blocklistTable,
      where: 'accountJid = ?',
      whereArgs: [await GetIt.I.get<XmppStateService>().getAccountJid()],
    );

    return GetIt.I
        .get<XmppConnection>()
        .getManagerById<BlockingManager>(blockingManager)!
        .unblockAll();
  }
}
