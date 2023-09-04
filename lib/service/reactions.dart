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
  Future<List<String>> getPreviewReactionsForMessage(
    String id,
    String accountJid,
  ) async {
    final reactions = await GetIt.I.get<DatabaseService>().database.query(
          reactionsTable,
          where: 'message_id = ? AND accountJid = ?',
          whereArgs: [id, accountJid],
          columns: ['emoji'],
          distinct: true,
          limit: 6,
        );

    return reactions.map((r) => r['emoji']! as String).toList();
  }

  Future<List<Reaction>> getReactionsForMessage(
    String id,
    String accountJid,
  ) async {
    final reactions = await GetIt.I.get<DatabaseService>().database.query(
      reactionsTable,
      where: 'message_id = ? AND accountJid = ?',
      whereArgs: [id, accountJid],
    );

    return reactions.map(Reaction.fromJson).toList();
  }

  Future<List<String>> getReactionsForMessageByJid(
    String id,
    String accountJid,
    String jid,
  ) async {
    final reactions = await GetIt.I.get<DatabaseService>().database.query(
      reactionsTable,
      where: 'message_id = ? AND accountJid = ? AND senderJid = ?',
      whereArgs: [id, accountJid, jid],
    );

    return reactions.map((r) => r['emoji']! as String).toList();
  }

  Future<int> _countReactions(
    String id,
    String accountJid,
    String emoji,
  ) async {
    return GetIt.I.get<DatabaseService>().database.count(
      reactionsTable,
      'message_id = ? AND accountJid = ? AND emoji = ?',
      [id, accountJid, emoji],
    );
  }

  /// Adds a new reaction [emoji], if possible, to the message with id [id] and returns the
  /// new message reaction preview.
  Future<Message?> addNewReaction(
    String id,
    String accountJid,
    String senderJid,
    String emoji,
  ) async {
    final ms = GetIt.I.get<MessageService>();
    var msg = await ms.getMessageById(id, accountJid);
    if (msg == null) {
      _log.warning(
        'Failed to get message ($id, $accountJid)',
      );
      return null;
    }

    _log.finest('Message reaction preview: ${msg.reactionsPreview}');
    await GetIt.I.get<DatabaseService>().database.insert(
          reactionsTable,
          Reaction(
            id,
            accountJid,
            senderJid,
            emoji,
          ).toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

    if (msg.reactionsPreview.length < 6 &&
        !msg.reactionsPreview.contains(emoji)) {
      msg = msg.copyWith(
        reactionsPreview: [
          ...msg.reactionsPreview,
          emoji,
        ],
      );
    }

    return msg;
  }

  Future<Message?> removeReaction(
    String id,
    String accountJid,
    String senderJid,
    String emoji,
  ) async {
    final ms = GetIt.I.get<MessageService>();
    final msg = await ms.getMessageById(id, accountJid);
    if (msg == null) {
      _log.warning(
        'Failed to get message ($id, $accountJid)',
      );
      return null;
    }

    final xss = GetIt.I.get<XmppStateService>();
    await GetIt.I.get<DatabaseService>().database.delete(
      reactionsTable,
      where:
          'message_id = ? AND accountJid = ? AND emoji = ? AND senderJid = ?',
      whereArgs: [
        id,
        accountJid,
        emoji,
        (await xss.state).jid,
      ],
    );
    final count = await _countReactions(id, accountJid, emoji);

    if (count > 0) {
      return msg;
    }

    final newPreview = List<String>.from(msg.reactionsPreview)..remove(emoji);
    return msg.copyWith(
      reactionsPreview: newPreview,
    );
  }

  Future<void> processNewReactions(
    Message msg,
    String accountJid,
    String senderJid,
    List<String> emojis,
  ) async {
    // Get all reactions know for this message
    final allReactions = await getReactionsForMessage(msg.id, accountJid);
    final userEmojis =
        allReactions.where((r) => r.senderJid == senderJid).map((r) => r.emoji);
    final removedReactions = userEmojis.where((e) => !emojis.contains(e));
    final addedReactions = emojis.where((e) => !userEmojis.contains(e));

    // Remove and add the new reactions
    final db = GetIt.I.get<DatabaseService>().database;
    for (final emoji in removedReactions) {
      final rows = await db.delete(
        reactionsTable,
        where:
            'message_id = ? AND accountJid = ? AND senderJid = ? AND emoji = ?',
        whereArgs: [msg.id, accountJid, senderJid, emoji],
      );
      assert(rows == 1, 'Only one row should be removed');
    }

    for (final emoji in addedReactions) {
      await db.insert(
        reactionsTable,
        Reaction(
          msg.id,
          accountJid,
          senderJid,
          emoji,
        ).toJson(),
      );
    }

    final newMessage = msg.copyWith(
      reactionsPreview: await getPreviewReactionsForMessage(
        msg.id,
        accountJid,
      ),
    );
    sendEvent(MessageUpdatedEvent(message: newMessage));
  }
}
