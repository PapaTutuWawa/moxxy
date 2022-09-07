import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/cache.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

class ConversationService {

  ConversationService()
    : _conversationCache = LRUCache(100),
      _loadedConversations = false;

  final LRUCache<int, Conversation> _conversationCache;
  bool _loadedConversations;

  /// Wrapper around DatabaseService's loadConversations that adds the loaded
  /// to the cache.
  Future<void> _loadConversations() async {
    final conversations = await GetIt.I.get<DatabaseService>().loadConversations();
    for (final c in conversations) {
      _conversationCache.cache(c.id, c);
    }
  }
      
  /// Returns the conversation with jid [jid] or null if not found.
  Future<Conversation?> getConversationByJid(String jid) async {
    if (!_loadedConversations) {
      await _loadConversations();
      _loadedConversations = true;
    }

    return firstWhereOrNull(
      // TODO(Unknown): Maybe have it accept an iterable
      _conversationCache.getValues(),
      (Conversation c) => c.jid == jid,
    );
  }

  /// Returns the conversation by its database id or null if it does not exist.
  Future<Conversation?> _getConversationById(int id) async {
    if (!_loadedConversations) {
      await _loadConversations();
      _loadedConversations = true;
    }

    return _conversationCache.getValue(id);
  }

  /// For modifying the cache without writing it to disk. Useful, for example, when
  /// changing the chat state.
  void setConversation(Conversation conversation) {
    _conversationCache.cache(conversation.id, conversation);
  }
  
  /// Wrapper around [DatabaseService]'s [updateConversation] that modifies the cache.
  Future<Conversation> updateConversation(int id, {
      String? lastMessageBody,
      int? lastChangeTimestamp,
      bool? open,
      int? unreadCounter,
      String? avatarUrl,
      List<SharedMedium>? sharedMedia,
      ChatState? chatState,
      bool? muted,
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
      sharedMedia: sharedMedia,
      chatState: conversation?.chatState ?? ChatState.gone,
      muted: muted,
    );

    _conversationCache.cache(id, newConversation);
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
    List<SharedMedium> sharedMedia,
    bool open,
    bool muted,
  ) async {
    final newConversation = await GetIt.I.get<DatabaseService>().addConversationFromData(
      title,
      lastMessageBody,
      avatarUrl,
      jid,
      unreadCounter,
      lastChangeTimestamp,
      sharedMedia,
      open,
      muted,
    );

    _conversationCache.cache(newConversation.id, newConversation);
    return newConversation;
  }
}
