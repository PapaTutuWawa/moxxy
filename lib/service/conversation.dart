import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/cache.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';

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
    int? lastChangeTimestamp,
    Message? lastMessage,
    bool? open,
    int? unreadCounter,
    String? avatarUrl,
    ChatState? chatState,
    bool? muted,
    bool? encrypted,
    Object? contactId = notSpecified,
  }) async {
    final conversation = (await _getConversationById(id))!;
    var newConversation = await GetIt.I.get<DatabaseService>().updateConversation(
      id,
      lastMessage: lastMessage,
      lastChangeTimestamp: lastChangeTimestamp,
      open: open,
      unreadCounter: unreadCounter,
      avatarUrl: avatarUrl,
      chatState: conversation.chatState,
      muted: muted,
      encrypted: encrypted,
      contactId: contactId,
    );

    // Copy over the old lastMessage if a new one was not set
    if (conversation.lastMessage != null && lastMessage == null) {
      newConversation = newConversation.copyWith(lastMessage: conversation.lastMessage);
    }
    
    _conversationCache.cache(id, newConversation);
    return newConversation;
  }

  /// Wrapper around [DatabaseService]'s [addConversationFromData] that updates the cache.
  Future<Conversation> addConversationFromData(
    String title,
    Message? lastMessage,
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
      lastMessage,
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
