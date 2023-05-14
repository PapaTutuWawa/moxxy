import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class ReactionWrapper {
  const ReactionWrapper(this.emojis, this.modified);

  final List<String> emojis;

  final bool modified;
}

class ReactionsService {
  final Logger _log = Logger('ReactionsService');

  /// Query the database for 6 distinct emoji reactions associated with the message id
  /// [id].
  Future<List<String>> getPreviewReactionsForMessage(int id) async {
    final reactions = await GetIt.I.get<DatabaseService>().database.query(
          reactionsTable,
          where: 'message_id = ?',
          whereArgs: [id],
          columns: ['emoji'],
          distinct: true,
          limit: 6,
        );

    return reactions.map((r) => r['emoji']! as String).toList();
  }

  Future<List<Reaction>> getReactionsForMessage(int id) async {
    final reactions = await GetIt.I.get<DatabaseService>().database.query(
      reactionsTable,
      where: 'message_id = ?',
      whereArgs: [id],
    );

    return reactions.map(Reaction.fromJson).toList();
  }

  Future<List<String>> getReactionsForMessageByJid(int id, String jid) async {
    final reactions = await GetIt.I.get<DatabaseService>().database.query(
      reactionsTable,
      where: 'message_id = ? AND senderJid = ?',
      whereArgs: [id, jid],
    );

    return reactions.map((r) => r['emoji']! as String).toList();
  }

  Future<int> _countReactions(int messageId, String emoji) async {
    return GetIt.I.get<DatabaseService>().database.count(
      reactionsTable,
      'message_id = ? AND emoji = ?',
      [messageId, emoji],
    );
  }

  /// Adds a new reaction [emoji], if possible, to [messageId] and returns the
  /// new message reaction preview.
  Future<Message?> addNewReaction(
    int messageId,
    String conversationJid,
    String emoji,
  ) async {
    final ms = GetIt.I.get<MessageService>();
    final msg = await ms.getMessageById(messageId, conversationJid);
    if (msg == null) {
      _log.warning('Failed to get message $messageId');
      return null;
    }

    if (!msg.reactionsPreview.contains(emoji) &&
        msg.reactionsPreview.length < 6) {
      final newPreview = [
        ...msg.reactionsPreview,
        emoji,
      ];

      try {
        final jid = (await GetIt.I.get<XmppStateService>().getXmppState()).jid!;
        await GetIt.I.get<DatabaseService>().database.insert(
              reactionsTable,
              Reaction(
                messageId,
                jid,
                emoji,
              ).toJson(),
              conflictAlgorithm: ConflictAlgorithm.fail,
            );

        final newMsg = msg.copyWith(
          reactionsPreview: newPreview,
        );
        await ms.replaceMessageInCache(newMsg);

        sendEvent(
          MessageUpdatedEvent(
            message: newMsg,
          ),
        );

        return newMsg;
      } catch (ex) {
        // The reaction already exists
        return msg;
      }
    }

    return msg;
  }

  Future<Message?> removeReaction(
    int messageId,
    String conversationJid,
    String emoji,
  ) async {
    final ms = GetIt.I.get<MessageService>();
    final msg = await ms.getMessageById(messageId, conversationJid);
    if (msg == null) {
      _log.warning('Failed to get message $messageId');
      return null;
    }

    await GetIt.I.get<DatabaseService>().database.delete(
      reactionsTable,
      where: 'message_id = ? AND emoji = ? AND senderJid = ?',
      whereArgs: [
        messageId,
        emoji,
        (await GetIt.I.get<XmppStateService>().getXmppState()).jid,
      ],
    );
    final count = await _countReactions(messageId, emoji);

    if (count > 0) {
      return msg;
    }

    final newPreview = List<String>.from(msg.reactionsPreview)..remove(emoji);
    final newMsg = msg.copyWith(
      reactionsPreview: newPreview,
    );
    await ms.replaceMessageInCache(newMsg);
    sendEvent(
      MessageUpdatedEvent(
        message: newMsg,
      ),
    );
    return newMsg;
  }

  Future<void> processNewReactions(
    Message msg,
    String senderJid,
    List<String> emojis,
  ) async {
    // Get all reactions know for this message
    final allReactions = await getReactionsForMessage(msg.id);
    final userEmojis =
        allReactions.where((r) => r.senderJid == senderJid).map((r) => r.emoji);
    final removedReactions = userEmojis.where((e) => !emojis.contains(e));
    final addedReactions = emojis.where((e) => !userEmojis.contains(e));

    // Remove and add the new reactions
    final db = GetIt.I.get<DatabaseService>().database;
    for (final emoji in removedReactions) {
      final rows = await db.delete(
        reactionsTable,
        where: 'message_id = ? AND senderJid = ? AND emoji = ?',
        whereArgs: [msg.id, senderJid, emoji],
      );
      assert(rows == 1, 'Only one row should be removed');
    }

    for (final emoji in addedReactions) {
      await db.insert(
        reactionsTable,
        Reaction(
          msg.id,
          senderJid,
          emoji,
        ).toJson(),
      );
    }

    final newMessage = msg.copyWith(
      reactionsPreview: await getPreviewReactionsForMessage(msg.id),
    );
    await GetIt.I.get<MessageService>().replaceMessageInCache(
          newMessage,
        );
    sendEvent(MessageUpdatedEvent(message: newMessage));
  }
}
