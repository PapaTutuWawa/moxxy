import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0191.dart';

enum BlockPushType {
  block,
  unblock
}

class BlocklistService {
  
  BlocklistService() :
    _blocklistCache = List.empty(growable: true),
    _requestedBlocklist = false;
  final List<String> _blocklistCache;
  bool _requestedBlocklist;

  Future<List<String>> _requestBlocklist() async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById<BlockingManager>(blockingManager)!;
    _blocklistCache
      ..clear()
      ..addAll(await manager.getBlocklist());
    _requestedBlocklist = true;
    return _blocklistCache;
  }
    
  /// Returns the blocklist from the database
  Future<List<String>> getBlocklist() async {
    if (!_requestedBlocklist) {
      _blocklistCache
        ..clear()
        ..addAll(await _requestBlocklist());
    }
   
    return _blocklistCache;
  }

  void onUnblockAllPush() {
    _blocklistCache.clear();
    sendEvent(
      BlocklistUnblockAllEvent(),
    );
  }
  
  Future<void> onBlocklistPush(BlockPushType type, List<String> items) async {
    // We will fetch it later when getBlocklist is called
    if (!_requestedBlocklist) return;

    final newBlocks = List<String>.empty(growable: true);
    final removedBlocks = List<String>.empty(growable: true);
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

    sendEvent(
      BlocklistPushEvent(
        added: newBlocks,
        removed: removedBlocks,
      ),
    );
  }

  Future<bool> blockJid(String jid) async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById<BlockingManager>(blockingManager)!;
    return manager.block([ jid ]);
  }

  Future<bool> unblockJid(String jid) async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById<BlockingManager>(blockingManager)!;
    return manager.unblock([ jid ]);
  }

  Future<bool> unblockAll() async {
    final manager = GetIt.I.get<XmppConnection>().getManagerById<BlockingManager>(blockingManager)!;
    return manager.unblockAll();
  }
}
