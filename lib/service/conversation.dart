import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:synchronized/synchronized.dart';

typedef CreateConversationCallback = Future<Conversation> Function();

typedef UpdateConversationCallback = Future<Conversation> Function(
  Conversation,
);

typedef PreRunConversationCallback = Future<void> Function(Conversation?);

class ConversationService {
  /// The list of known conversations.
  Map<String, Conversation>? _conversationCache;

  /// The lock for accessing _conversationCache
  final Lock _lock = Lock();

  /// When called with a JID [jid], then first, if non-null, [preRun] is
  /// executed.
  /// Next, if a conversation with JID [jid] exists, [update] is called with
  /// the conversation as its argument. If not, then [create] is executed.
  /// Returns either the result of [create], [update] or null.
  Future<Conversation?> createOrUpdateConversation(
    String jid, {
    CreateConversationCallback? create,
    UpdateConversationCallback? update,
    PreRunConversationCallback? preRun,
  }) async {
    return _lock.synchronized(() async {
      final conversation = await _getConversationByJid(jid);

      // Pre run
      if (preRun != null) {
        await preRun(conversation);
      }

      if (conversation != null) {
        // Conversation exists
        if (update != null) {
          return update(conversation);
        }
      } else {
        // Conversation does not exist
        if (create != null) {
          return create();
        }
      }

      return null;
    });
  }

  /// Wrapper around DatabaseService's loadConversations that adds the loaded
  /// to the cache.
  Future<void> _loadConversationsIfNeeded() async {
    if (_conversationCache != null) return;

    final conversations =
        await GetIt.I.get<DatabaseService>().loadConversations();
    _conversationCache = Map<String, Conversation>.fromEntries(
      conversations.map((c) => MapEntry(c.jid, c)),
    );
  }

  /// Returns the conversation with jid [jid] or null if not found.
  Future<Conversation?> _getConversationByJid(String jid) async {
    await _loadConversationsIfNeeded();
    return _conversationCache![jid];
  }

  /// Wrapper around [ConversationService._getConversationByJid] that aquires
  /// the lock for the cache.
  Future<Conversation?> getConversationByJid(String jid) async {
    return _lock.synchronized(() async => _getConversationByJid(jid));
  }

  /// For modifying the cache without writing it to disk. Useful, for example, when
  /// changing the chat state.
  void setConversation(Conversation conversation) {
    _conversationCache![conversation.jid] = conversation;
  }

  /// Wrapper around [DatabaseService]'s [updateConversation] that modifies the cache.
  /// To prevent issues with the cache, only call from within
  /// [ConversationService.createOrUpdateConversation].
  Future<Conversation> updateConversation(
    String jid, {
    int? lastChangeTimestamp,
    Message? lastMessage,
    bool? open,
    int? unreadCounter,
    String? avatarUrl,
    ChatState? chatState,
    bool? muted,
    bool? encrypted,
    Object? contactId = notSpecified,
    Object? contactAvatarPath = notSpecified,
    Object? contactDisplayName = notSpecified,
    int? sharedMediaAmount,
  }) async {
    final conversation = (await _getConversationByJid(jid))!;
    var newConversation =
        await GetIt.I.get<DatabaseService>().updateConversation(
              jid,
              lastMessage: lastMessage,
              lastChangeTimestamp: lastChangeTimestamp,
              open: open,
              unreadCounter: unreadCounter,
              avatarUrl: avatarUrl,
              chatState: conversation.chatState,
              muted: muted,
              encrypted: encrypted,
              contactId: contactId,
              contactAvatarPath: contactAvatarPath,
              contactDisplayName: contactDisplayName,
              sharedMediaAmount: sharedMediaAmount,
            );

    // Copy over the old lastMessage if a new one was not set
    if (conversation.lastMessage != null && lastMessage == null) {
      newConversation =
          newConversation.copyWith(lastMessage: conversation.lastMessage);
    }

    _conversationCache![jid] = newConversation;
    return newConversation;
  }

  /// Wrapper around [DatabaseService]'s [addConversationFromData] that updates the
  /// cache.
  /// To prevent issues with the cache, only call from within
  /// [ConversationService.createOrUpdateConversation].
  Future<Conversation> addConversationFromData(
    String title,
    Message? lastMessage,
    ConversationType type,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    bool open,
    bool muted,
    bool encrypted,
    int sharedMediaAmount,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
  ) async {
    final newConversation =
        await GetIt.I.get<DatabaseService>().addConversationFromData(
              title,
              lastMessage,
              type,
              avatarUrl,
              jid,
              unreadCounter,
              lastChangeTimestamp,
              open,
              muted,
              encrypted,
              sharedMediaAmount,
              contactId,
              contactAvatarPath,
              contactDisplayName,
            );

    if (_conversationCache != null) {
      _conversationCache![newConversation.jid] = newConversation;
    }

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
