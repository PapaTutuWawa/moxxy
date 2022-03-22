import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0191.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";

enum BlockPushType {
  block,
  unblock
}

class BlocklistService {
  final List<String> _blocklistCache;
  bool _requestedBlocklist;

  final Logger _log;
  
  BlocklistService() :
    _blocklistCache = List.empty(growable: true),
    _requestedBlocklist = false,
    _log = Logger("BlocklistService");

  Future<List<String>> _requestBlocklist() async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById(blockingManager)! as BlockingManager;
    _blocklistCache.clear();
    _blocklistCache.addAll(await manager.getBlocklist());
    // TODO
    /*
    sendData(
      BlocklistDiffEvent(
        newBlockedItems: _blocklistCache
      )
    );
    */
    _requestedBlocklist = true;
    return _blocklistCache;
  }
    
  /// Returns the blocklist from the database
  Future<List<String>> getBlocklist() async {
    if (!_requestedBlocklist) {
      _blocklistCache.clear();
      _blocklistCache.addAll(await _requestBlocklist());
    }
   
    return _blocklistCache;
  }

  void onUnblockAllPush() {
    // TODO
    /*
    sendData(
      BlocklistDiffEvent(
        removedBlockedItems: _blocklistCache
      )
    );
    */

    _blocklistCache.clear();
  }
  
  Future<void> onBlocklistPush(BlockPushType type, List<String> items) async {
    if (!_requestedBlocklist) await getBlocklist();

    final List<String> newBlocks = List.empty(growable: true);
    final List<String> removedBlocks = List.empty(growable: true);
    for (final item in items) {
      switch (type) {
        case BlockPushType.block: {
          if (_blocklistCache.contains(item)) continue;

          _blocklistCache.add(item);
          newBlocks.add(item);
        }
        break;
        case BlockPushType.unblock: {
          _blocklistCache.removeWhere((i) => i == item);
          removedBlocks.add(item);
        }
        break;
      }
    }

    // TODO
    /*
    sendData(
      BlocklistDiffEvent(
        newBlockedItems: newBlocks,
        removedBlockedItems: removedBlocks
      )
    );
    */
  }

  Future<bool> blockJid(String jid) async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById(blockingManager)! as BlockingManager;
    return await manager.block([ jid ]);
  }

  Future<bool> unblockJid(String jid) async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById(blockingManager)! as BlockingManager;
    return await manager.unblock([ jid ]);
  }

  Future<bool> unblockAll() async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById(blockingManager)! as BlockingManager;
    return await manager.unblockAll();
  }
}
