import "dart:collection";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/db/media.dart";
import "package:moxxyv2/xmpp/xeps/xep_0085.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";

class ConversationService {
  final Logger _log;

  final HashMap<int, Conversation> _conversationCache;
  bool _loadedConversations;

  ConversationService()
    : _conversationCache = HashMap(),
      _loadedConversations = false,
      _log = Logger("ConversationService");

  /// Wrapper around [DatabaseService]'s [loadConversations] that adds the loaded
  /// to the cache.
  Future<void> _loadConversations() async {
    final conversations = await GetIt.I.get<DatabaseService>().loadConversations();
    for (final c in conversations) {
      _conversationCache[c.id] = c;
    }
  }
      
  /// Returns the conversation with jid [jid] or null if not found.
  Future<Conversation?> getConversationByJid(String jid) async {
    if (!_loadedConversations) {
      await _loadConversations();
      _loadedConversations = true;
    }

    return firstWhereOrNull(
      // TODO: Maybe have it accept an iterable
      _conversationCache.values.toList(),
      (Conversation c) => c.jid == jid
    );
  }

  /// Returns the conversation by its database id or null if it does not exist.
  Future<Conversation?> _getConversationById(int id) async {
    if (!_loadedConversations) {
      await _loadConversations();
      _loadedConversations = true;
    }

    return _conversationCache[id];
  }

  /// For modifying the cache without writing it to disk. Useful, for example, when
  /// changing the chat state.
  void setConversation(Conversation conversation) {
    _conversationCache[conversation.id] = conversation;
  }
  
  /// Wrapper around [DatabaseService]'s [updateConversation] that modifies the cache.
  Future<Conversation> updateConversation(int id, {
      String? lastMessageBody,
      int? lastChangeTimestamp,
      bool? open,
      int? unreadCounter,
      String? avatarUrl,
      DBSharedMedium? sharedMedium,
      ChatState? chatState
    }
  ) async {
    final conversation = await _getConversationById(id);
    final newConversation = await GetIt.I.get<DatabaseService>().updateConversation(
      id,
      lastMessageBody: lastMessageBody,
      lastChangeTimestamp: lastChangeTimestamp,
      open: open,
      unreadCounter: unreadCounter,
      avatarUrl: avatarUrl,
      sharedMedium: sharedMedium,
      chatState: conversation?.chatState ?? ChatState.gone
    );

    _conversationCache[id] = newConversation;
    return newConversation;
  }

  /// Wrapper around [DatabaseService]'s [addConversationFromData] that updates the cache.
  Future<Conversation> addConversationFromData(
    String title,
    String lastMessageBody,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    List<DBSharedMedium> sharedMedia,
    bool open
  ) async {
    final newConversation = await GetIt.I.get<DatabaseService>().addConversationFromData(
      title,
      lastMessageBody,
      avatarUrl,
      jid,
      unreadCounter,
      lastChangeTimestamp,
      sharedMedia,
      open
    );

    _conversationCache[newConversation.id] = newConversation;
    return newConversation;
  }
}
