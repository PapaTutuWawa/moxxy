import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/cache.dart';
import 'package:moxxyv2/shared/models/conversation.dart';

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
    bool? lastMessageRetracted,
    int? lastMessageId,
    bool? open,
    int? unreadCounter,
    String? avatarUrl,
    ChatState? chatState,
    bool? muted,
    bool? encrypted,
  }) async {
    final conversation = await _getConversationById(id);
    final newConversation = await GetIt.I.get<DatabaseService>().updateConversation(
      id,
      lastMessageBody: lastMessageBody,
      lastMessageRetracted: lastMessageRetracted,
      lastMessageId: lastMessageId,
      lastChangeTimestamp: lastChangeTimestamp,
      open: open,
      unreadCounter: unreadCounter,
      avatarUrl: avatarUrl,
      chatState: conversation?.chatState ?? ChatState.gone,
      muted: muted,
      encrypted: encrypted,
    );

    _conversationCache.cache(id, newConversation);
    return newConversation;
  }

  /// Wrapper around [DatabaseService]'s [addConversationFromData] that updates the cache.
  Future<Conversation> addConversationFromData(
    String title,
    int lastMessageId,
    bool lastMessageRetracted,
    String lastMessageBody,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    bool open,
    bool muted,
    bool encrypted,
  ) async {
    final newConversation = await GetIt.I.get<DatabaseService>().addConversationFromData(
      title,
      lastMessageId,
      lastMessageRetracted,
      lastMessageBody,
      avatarUrl,
      jid,
      unreadCounter,
      lastChangeTimestamp,
      open,
      muted,
      encrypted,
    );

    _conversationCache.cache(newConversation.id, newConversation);
    return newConversation;
  }

  /// Returns true if the stanzas to the conversation with [jid] should be encrypted.
  /// If not, returns false.
  ///
  /// If the conversation does not exist, then the value of the preference for
  /// enableOmemoByDefault is used.
  Future<bool> shouldEncryptForConversation(JID jid) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    final conversation = await getConversationByJid(jid.toString());
    return conversation?.encrypted ?? prefs.enableOmemoByDefault;
  }
}
