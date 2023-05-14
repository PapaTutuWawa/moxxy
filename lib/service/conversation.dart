import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
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

  /// Loads all conversations from the database and adds them to the state and cache.
  Future<List<Conversation>> loadConversations() async {
    final db = GetIt.I.get<DatabaseService>().database;
    final conversationsRaw = await db.query(
      conversationsTable,
      orderBy: 'lastChangeTimestamp DESC',
    );

    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final jid = c['jid']! as String;
      final rosterItem =
          await GetIt.I.get<RosterService>().getRosterItemByJid(jid);

      Message? lastMessage;
      if (c['lastMessageId'] != null) {
        lastMessage = await GetIt.I.get<MessageService>().getMessageById(
              c['lastMessageId']! as int,
              jid,
              queryReactionPreview: false,
            );
      }

      tmp.add(
        Conversation.fromDatabaseJson(
          c,
          rosterItem != null && !rosterItem.pseudoRosterItem,
          rosterItem?.subscription ?? 'none',
          lastMessage,
        ),
      );
    }

    return tmp;
  }

  /// Wrapper around DatabaseService's loadConversations that adds the loaded
  /// to the cache.
  Future<void> _loadConversationsIfNeeded() async {
    if (_conversationCache != null) return;

    final conversations = await loadConversations();
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

  /// Updates the conversation with JID [jid] inside the database.
  ///
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
  }) async {
    final conversation = (await _getConversationByJid(jid))!;

    final c = <String, dynamic>{};

    if (lastMessage != null) {
      c['lastMessageId'] = lastMessage.id;
    }
    if (lastChangeTimestamp != null) {
      c['lastChangeTimestamp'] = lastChangeTimestamp;
    }
    if (open != null) {
      c['open'] = boolToInt(open);
    }
    if (unreadCounter != null) {
      c['unreadCounter'] = unreadCounter;
    }
    if (avatarUrl != null) {
      c['avatarUrl'] = avatarUrl;
    }
    if (muted != null) {
      c['muted'] = boolToInt(muted);
    }
    if (encrypted != null) {
      c['encrypted'] = boolToInt(encrypted);
    }
    if (contactId != notSpecified) {
      c['contactId'] = contactId as String?;
    }
    if (contactAvatarPath != notSpecified) {
      c['contactAvatarPath'] = contactAvatarPath as String?;
    }
    if (contactDisplayName != notSpecified) {
      c['contactDisplayName'] = contactDisplayName as String?;
    }

    final result =
        await GetIt.I.get<DatabaseService>().database.updateAndReturn(
      conversationsTable,
      c,
      where: 'jid = ?',
      whereArgs: [jid],
    );

    final rosterItem =
        await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    var newConversation = Conversation.fromDatabaseJson(
      result,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      lastMessage,
    );

    // Copy over the old lastMessage if a new one was not set
    if (conversation.lastMessage != null && lastMessage == null) {
      newConversation =
          newConversation.copyWith(lastMessage: conversation.lastMessage);
    }

    _conversationCache![jid] = newConversation;
    return newConversation;
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  ///
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
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
  ) async {
    final rosterItem =
        await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    final newConversation = Conversation(
      title,
      lastMessage,
      avatarUrl,
      jid,
      unreadCounter,
      type,
      lastChangeTimestamp,
      open,
      rosterItem != null && !rosterItem.pseudoRosterItem,
      rosterItem?.subscription ?? 'none',
      muted,
      encrypted,
      ChatState.gone,
      contactId: contactId,
      contactAvatarPath: contactAvatarPath,
      contactDisplayName: contactDisplayName,
    );
    await GetIt.I.get<DatabaseService>().database.insert(
          conversationsTable,
          newConversation.toDatabaseJson(),
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
