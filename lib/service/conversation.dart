import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/groupchat.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/groupchat.dart';
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

  final Logger _log = Logger('ConversationService');

  String? _activeConversationJid;

  String? get activeConversationJid => _activeConversationJid;

  set activeConversationJid(String? jid) {
    _log.finest('Setting activeConversationJid to $jid');
    _activeConversationJid = jid;
  }

  /// When called with a JID [jid], then first, if non-null, [preRun] is
  /// executed.
  /// Next, if a conversation with JID [jid] exists, [update] is called with
  /// the conversation as its argument. If not, then [create] is executed.
  /// Returns either the result of [create], [update] or null.
  Future<Conversation?> createOrUpdateConversation(
    String jid,
    String accountJid, {
    CreateConversationCallback? create,
    UpdateConversationCallback? update,
    PreRunConversationCallback? preRun,
  }) async {
    return _lock.synchronized(() async {
      final conversation = await _getConversationByJid(jid, accountJid);

      // Pre run
      if (preRun != null) {
        await preRun(conversation);
      }

      _log.finest(
        '[createOrUpdateConversation] Got conversation: $conversation',
      );
      if (conversation != null) {
        // Conversation exists
        if (update != null) {
          final updatedConversation = await update(conversation);
          assert(
            updatedConversation.jid == conversation.jid,
            'Cannot change the JID of a conversation',
          );
          assert(
            _conversationCache!.containsKey(updatedConversation.jid),
            'Conversation JID must already be in cache',
          );

          // Update the cache
          _conversationCache![updatedConversation.jid] = updatedConversation;
          return updatedConversation;
        }
      } else {
        // Conversation does not exist
        if (create != null) {
          final newConversation = await create();

          // Update the cache
          _conversationCache![newConversation.jid] = newConversation;
          return newConversation;
        }
      }

      return null;
    });
  }

  /// Search for conversations associated with the account [accountJid],
  /// where the title or the last message's body contains [text].
  Future<List<Conversation>> searchConversations(
    String accountJid,
    String text,
  ) async {
    // TODO(Unknown): Optimize so that we don't have to do a second query (last message)$
    //                for the matching conversations.
    final db = GetIt.I.get<DatabaseService>().database;
    final gs = GetIt.I.get<GroupchatService>();

    final textQuery = '%$text%';
    final conversationsRaw = await db.rawQuery(
      '''
SELECT
  *
FROM
  $conversationsTable AS conversations
LEFT JOIN
  $messagesTable lm ON lm.id = conversations.lastMessageId
WHERE
  conversations.accountJid = ? AND (
    conversations.title LIKE ? OR lm.body LIKE ?
  )
ORDER BY
  lastChangeTimestamp DESC''',
      [
        accountJid,
        textQuery,
        textQuery,
      ],
    );
    _log.finest(
      'Conversation search returned ${conversationsRaw.length} conversations',
    );

    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final jid = c['jid']! as String;
      final rosterItem = await GetIt.I
          .get<RosterService>()
          .getRosterItemByJid(jid, accountJid);

      Message? lastMessage;
      if (c['lastMessageId'] != null) {
        lastMessage = await GetIt.I.get<MessageService>().getMessageById(
              c['lastMessageId']! as String,
              accountJid,
              queryReactionPreview: false,
            );
      }

      GroupchatDetails? groupchatDetails;
      if (c['type'] == ConversationType.groupchat.value) {
        groupchatDetails = await gs.getGroupchatDetailsByJid(
          c['jid']! as String,
          accountJid,
        );
      }

      tmp.add(
        Conversation.fromDatabaseJson(
          c,
          rosterItem?.showAddToRosterButton ?? true,
          lastMessage,
          groupchatDetails,
        ),
      );
    }

    return tmp;
  }

  /// Loads all conversations from the database and adds them to the state and cache.
  Future<List<Conversation>> loadConversations(String accountJid) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final gs = GetIt.I.get<GroupchatService>();

    final conversationsRaw = await db.query(
      conversationsTable,
      where: 'accountJid = ?',
      whereArgs: [
        accountJid,
      ],
      orderBy: 'lastChangeTimestamp DESC',
    );

    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final jid = c['jid']! as String;
      final rosterItem = await GetIt.I
          .get<RosterService>()
          .getRosterItemByJid(jid, accountJid);

      Message? lastMessage;
      if (c['lastMessageId'] != null) {
        lastMessage = await GetIt.I.get<MessageService>().getMessageById(
              c['lastMessageId']! as String,
              accountJid,
              queryReactionPreview: false,
            );
      }

      GroupchatDetails? groupchatDetails;
      if (c['type'] == ConversationType.groupchat.value) {
        groupchatDetails = await gs.getGroupchatDetailsByJid(
          c['jid']! as String,
          accountJid,
        );
      }

      tmp.add(
        Conversation.fromDatabaseJson(
          c,
          rosterItem?.showAddToRosterButton ?? true,
          lastMessage,
          groupchatDetails,
        ),
      );
    }

    return tmp;
  }

  /// Wrapper around DatabaseService's loadConversations that adds the loaded
  /// to the cache.
  Future<void> _loadConversationsIfNeeded(String accountJid) async {
    if (_conversationCache != null) return;

    final conversations = await loadConversations(accountJid);
    _conversationCache = Map<String, Conversation>.fromEntries(
      conversations.map((c) => MapEntry(c.jid, c)),
    );

    _log.finest(
      'Conversation Cache loaded: ${_conversationCache!.keys.toList()}',
    );
  }

  /// Returns the conversation with jid [jid] or null if not found.
  Future<Conversation?> _getConversationByJid(
    String jid,
    String accountJid,
  ) async {
    await _loadConversationsIfNeeded(accountJid);

    _log.finest('[_getConversationByJid] Requested JID $jid');
    return _conversationCache![jid];
  }

  /// Wrapper around [ConversationService._getConversationByJid] that aquires
  /// the lock for the cache.
  Future<Conversation?> getConversationByJid(
    String jid,
    String accountJid,
  ) async {
    return _lock
        .synchronized(() async => _getConversationByJid(jid, accountJid));
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
    String jid,
    String accountJid, {
    int? lastChangeTimestamp,
    Message? lastMessage,
    bool? open,
    int? unreadCounter,
    String? avatarPath,
    Object? avatarHash = notSpecified,
    ChatState? chatState,
    bool? muted,
    bool? encrypted,
    Object? contactId = notSpecified,
    Object? contactAvatarPath = notSpecified,
    Object? contactDisplayName = notSpecified,
    GroupchatDetails? groupchatDetails,
    bool? favourite,
  }) async {
    final conversation = (await _getConversationByJid(jid, accountJid))!;

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
    if (avatarPath != null) {
      c['avatarPath'] = avatarPath;
    }
    if (avatarHash != notSpecified) {
      c['avatarHash'] = avatarHash as String?;
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
    if (favourite != null) {
      c['favourite'] = boolToInt(favourite);
    }

    final result =
        await GetIt.I.get<DatabaseService>().database.updateAndReturn(
      conversationsTable,
      c,
      where: 'jid = ? AND accountJid = ?',
      whereArgs: [jid, accountJid],
    );

    final rosterItem =
        await GetIt.I.get<RosterService>().getRosterItemByJid(jid, accountJid);
    var newConversation = Conversation.fromDatabaseJson(
      result,
      rosterItem?.showAddToRosterButton ?? true,
      lastMessage,
      groupchatDetails ?? conversation.groupchatDetails,
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
    String accountJid,
    String title,
    Message? lastMessage,
    ConversationType type,
    String? avatarPath,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    bool open,
    bool muted,
    bool encrypted,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
    GroupchatDetails? groupchatDetails,
  ) async {
    final rosterItem =
        await GetIt.I.get<RosterService>().getRosterItemByJid(jid, accountJid);
    final gs = GetIt.I.get<GroupchatService>();
    final newConversation = Conversation(
      accountJid,
      title,
      lastMessage,
      avatarPath,
      null,
      jid,
      groupchatDetails,
      unreadCounter,
      type,
      lastChangeTimestamp,
      open,
      rosterItem?.showAddToRosterButton ?? true,
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

    if (type == ConversationType.groupchat && groupchatDetails != null) {
      await gs.addGroupchatDetailsFromData(
        jid,
        accountJid,
        groupchatDetails.nick,
      );
    }

    return newConversation;
  }

  /// Returns true if the stanzas to the conversation with [jid] should be encrypted.
  /// If not, returns false.
  ///
  /// If the conversation does not exist, then the value of the preference for
  /// enableOmemoByDefault is used.
  Future<bool> shouldEncryptForConversation(JID jid, String accountJid) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    final conversation = await getConversationByJid(jid.toString(), accountJid);
    return conversation?.encrypted ?? prefs.enableOmemoByDefault;
  }

  /// Send a chat state [state] to [jid], if certain pre-conditions are met:
  /// - We have a network connection
  /// - Sending chat markers/states are enabled
  /// - [jid] != '' (not the self-chat)
  /// [type] is the type of chat the chat state should be sent within.
  Future<void> sendChatState(
    ConversationType type,
    String jid,
    ChatState state,
  ) async {
    if (type != ConversationType.chat) {
      _log.finest('Not sending chat state because chat type is $type');
      return;
    }

    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    // Only send chat states if the users wants to send them
    if (!prefs.sendChatMarkers) return;

    // Only send chat states when we're connected
    // TODO(Unknown): Maybe queue it up intelligently
    if (!(await GetIt.I.get<ConnectivityService>().hasConnection())) return;

    final conn = GetIt.I.get<XmppConnection>();

    await conn
        .getManagerById<ChatStateManager>(chatStateManager)!
        .sendChatState(
          state,
          jid,
          messageType: type.toMessageType(),
        );
  }
}
