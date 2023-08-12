import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/files.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/reactions.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/warning_types.dart';

class MessageService {
  /// Logger
  final Logger _log = Logger('MessageService');

  Future<Message> _parseMessage(
    Map<String, Object?> rawMessage,
    String accountJid,
    bool queryReactionPreview,
  ) async {
    final db = GetIt.I.get<DatabaseService>().database;
    FileMetadata? fm;
    if (rawMessage['file_metadata_id'] != null) {
      final rawFm = (await db.query(
        fileMetadataTable,
        where: 'id = ?',
        whereArgs: [rawMessage['file_metadata_id']],
        limit: 1,
      ))
          .first;
      fm = FileMetadata.fromDatabaseJson(rawFm);
    }

    return Message.fromDatabaseJson(
      rawMessage,
      null,
      fm,
      queryReactionPreview
          ? await GetIt.I.get<ReactionsService>().getPreviewReactionsForMessage(
                rawMessage['sid']! as String,
                rawMessage['conversationJid']! as String,
                accountJid,
              )
          : [],
    );
  }

  /// Queries the database for a message with a stanza id of [sid] inside
  /// the conversation [conversationJid] in the context of the account
  /// [accountJid].
  Future<Message?> getMessageBySid(
    String sid,
    String conversationJid,
    String accountJid, {
    bool queryReactionPreview = true,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final messagesRaw = await db.query(
      messagesTable,
      where: 'sid = ? AND conversationJid = ? AND accountJid = ?',
      whereArgs: [sid, conversationJid, accountJid],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    return _parseMessage(messagesRaw.first, accountJid, queryReactionPreview);
  }

  /// Queries the database for a message with a stanza id of [originId] inside
  /// the conversation [conversationJid] in the context of the account
  /// [accountJid].
  Future<Message?> getMessageByOriginId(
    String originId,
    String conversationJid,
    String accountJid, {
    bool queryReactionPreview = true,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final messagesRaw = await db.query(
      messagesTable,
      where: 'conversationJid = ? AND accountJid = ? AND originId = ?',
      whereArgs: [
        conversationJid,
        accountJid,
        originId,
      ],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    return _parseMessage(messagesRaw.first, accountJid, queryReactionPreview);
  }

  /// Return a list of messages for [jid]. If [olderThan] is true, then all messages are older than [oldestTimestamp], if
  /// specified, or the oldest messages are returned if null. If [olderThan] is false, then message must be newer
  /// than [oldestTimestamp], or the newest messages are returned if null.
  Future<List<Message>> getPaginatedMessagesForJid(
    String jid,
    String accountJid,
    bool olderThan,
    int? oldestTimestamp,
  ) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final comparator = olderThan ? '<' : '>';
    final query = oldestTimestamp != null
        ? 'conversationJid = ? AND accountJid = ? AND timestamp $comparator ?'
        : 'conversationJid = ? AND accountJid = ?';
    final rawMessages = await db.rawQuery(
      // LEFT JOIN $messagesTable quote ON msg.quote_id = quote.id
      '''
SELECT
  msg.*,
  quote.sender AS quote_sender,
  quote.body AS quote_body,
  quote.timestamp AS quote_timestamp,
  quote.sid AS quote_sid,
  quote.conversationJid AS quote_conversationJid,
  quote.isFileUploadNotification AS quote_isFileUploadNotification,
  quote.encrypted AS quote_encrypted,
  quote.errorType AS quote_errorType,
  quote.warningType AS quote_warningType,
  quote.received AS quote_received,
  quote.displayed AS quote_displayed,
  quote.acked AS quote_acked,
  quote.originId AS quote_originId,
  quote.quote_sid AS quote_quote_sid,
  quote.file_metadata_id AS quote_file_metadata_id,
  quote.isDownloading AS quote_isDownloading,
  quote.isUploading AS quote_isUploading,
  quote.isRetracted AS quote_isRetracted,
  quote.isEdited AS quote_isEdited,
  quote.containsNoStore AS quote_containsNoStore,
  quote.stickerPackId AS quote_stickerPackId,
  quote.pseudoMessageType AS quote_pseudoMessageType,
  quote.pseudoMessageData AS quote_pseudoMessageData,
  fm.id as fm_id,
  fm.path as fm_path,
  fm.sourceUrls as fm_sourceUrls,
  fm.mimeType as fm_mimeType,
  fm.thumbnailType as fm_thumbnailType,
  fm.thumbnailData as fm_thumbnailData,
  fm.width as fm_width,
  fm.height as fm_height,
  fm.plaintextHashes as fm_plaintextHashes,
  fm.encryptionKey as fm_encryptionKey,
  fm.encryptionIv as fm_encryptionIv,
  fm.encryptionScheme as fm_encryptionScheme,
  fm.cipherTextHashes as fm_cipherTextHashes,
  fm.filename as fm_filename,
  fm.size as fm_size
FROM (SELECT * FROM $messagesTable WHERE $query ORDER BY timestamp DESC LIMIT $messagePaginationSize) AS msg
  LEFT JOIN $fileMetadataTable fm ON msg.file_metadata_id = fm.id
  LEFT JOIN $messagesTable quote ON msg.quote_sid = quote.sid;
      ''',
      [
        jid,
        accountJid,
        if (oldestTimestamp != null) oldestTimestamp,
      ],
    );

    final page = List<Message>.empty(growable: true);
    for (final m in rawMessages) {
      if (m.isEmpty) {
        continue;
      }

      Message? quotes;
      if (m['quote_sid'] != null) {
        final rawQuote = getPrefixedSubMap(m, 'quote_');

        FileMetadata? quoteFm;
        if (rawQuote['file_metadata_id'] != null) {
          final rawQuoteFm = (await db.query(
            fileMetadataTable,
            where: 'id = ?',
            whereArgs: [rawQuote['file_metadata_id']],
            limit: 1,
          ))
              .first;
          quoteFm = FileMetadata.fromDatabaseJson(rawQuoteFm);
        }

        quotes = Message.fromDatabaseJson(rawQuote, null, quoteFm, []);
      }

      FileMetadata? fm;
      if (m['file_metadata_id'] != null) {
        fm = FileMetadata.fromDatabaseJson(
          getPrefixedSubMap(m, 'fm_'),
        );
      }

      page.add(
        Message.fromDatabaseJson(
          m,
          quotes,
          fm,
          await GetIt.I.get<ReactionsService>().getPreviewReactionsForMessage(
                m['sid']! as String,
                jid,
                accountJid,
              ),
        ),
      );
    }

    return page;
  }

  /// Like getPaginatedMessagesForJid, but instead only returns messages that have file
  /// metadata attached. This method bypasses the cache and does not load the message's
  /// quoted message, if it exists. If [jid] is set to null, then the media messages for
  /// all conversations are queried.
  Future<List<Message>> getPaginatedSharedMediaMessagesForJid(
    String? jid,
    String accountJid,
    bool olderThan,
    int? oldestTimestamp,
  ) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final comparator = olderThan ? '<' : '>';
    final queryPrefix = jid != null
        ? 'conversationJid = ? accountJid = ? AND'
        : 'accountJid = ?';
    final query = oldestTimestamp != null
        ? 'file_metadata_id IS NOT NULL AND timestamp $comparator ?'
        : 'file_metadata_id IS NOT NULL';
    final rawMessages = await db.rawQuery(
      '''
SELECT
  msg.*,
  fm.id as fm_id,
  fm.path as fm_path,
  fm.sourceUrls as fm_sourceUrls,
  fm.mimeType as fm_mimeType,
  fm.thumbnailType as fm_thumbnailType,
  fm.thumbnailData as fm_thumbnailData,
  fm.width as fm_width,
  fm.height as fm_height,
  fm.plaintextHashes as fm_plaintextHashes,
  fm.encryptionKey as fm_encryptionKey,
  fm.encryptionIv as fm_encryptionIv,
  fm.encryptionScheme as fm_encryptionScheme,
  fm.cipherTextHashes as fm_cipherTextHashes,
  fm.filename as fm_filename,
  fm.size as fm_size
FROM
  (SELECT
    *
  FROM
    $messagesTable
  WHERE
    $queryPrefix $query
    ORDER BY timestamp
    DESC LIMIT $sharedMediaPaginationSize
  ) AS msg
  LEFT JOIN
    $fileMetadataTable fm
    ON
      msg.file_metadata_id = fm.id
    WHERE
      fm_path IS NOT NULL
      AND NOT EXISTS (SELECT id FROM $stickersTable WHERE file_metadata_id = fm.id);
      ''',
      [
        if (jid != null) jid,
        accountJid,
        if (oldestTimestamp != null) oldestTimestamp,
      ],
    );

    final page = List<Message>.empty(growable: true);
    for (final m in rawMessages) {
      if (m.isEmpty) {
        continue;
      }

      page.add(
        Message.fromDatabaseJson(
          m,
          null,
          FileMetadata.fromDatabaseJson(
            getPrefixedSubMap(m, 'fm_'),
          ),
          await GetIt.I.get<ReactionsService>().getPreviewReactionsForMessage(
                m['sid']! as String,
                m['conversationJid']! as String,
                accountJid,
              ),
        ),
      );
    }

    return page;
  }

  /// Wrapper around [DatabaseService]'s addMessageFromData that updates the cache.
  Future<Message> addMessageFromData(
    String accountJid,
    String body,
    int timestamp,
    String sender,
    String conversationJid,
    String sid,
    bool isFileUploadNotification,
    bool encrypted,
    bool containsNoStore, {
    String? originId,
    String? quoteId,
    FileMetadata? fileMetadata,
    MessageErrorType? errorType,
    MessageWarningType? warningType,
    bool isDownloading = false,
    bool isUploading = false,
    String? stickerPackId,
    PseudoMessageType? pseudoMessageType,
    Map<String, dynamic>? pseudoMessageData,
    bool received = false,
    bool displayed = false,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    var message = Message(
      accountJid,
      sender,
      body,
      timestamp,
      sid,
      conversationJid,
      isFileUploadNotification,
      encrypted,
      containsNoStore,
      errorType: errorType,
      warningType: warningType,
      fileMetadata: fileMetadata,
      received: received,
      displayed: displayed,
      acked: false,
      originId: originId,
      isUploading: isUploading,
      isDownloading: isDownloading,
      stickerPackId: stickerPackId,
      pseudoMessageType: pseudoMessageType,
      pseudoMessageData: pseudoMessageData,
    );

    if (quoteId != null) {
      final quotes =
          await getMessageBySid(quoteId, conversationJid, accountJid);
      if (quotes == null) {
        _log.warning('Failed to add quote for message with id $quoteId');
      } else {
        message = message.copyWith(quotes: quotes);
      }
    }

    await db.insert(messagesTable, message.toDatabaseJson());
    return message;
  }

  /// Wrapper around [DatabaseService]'s updateMessage that updates the cache
  Future<Message> updateMessage(
    String sid,
    String conversationJid,
    String accountJid, {
    String? newSid,
    Object? body = notSpecified,
    bool? received,
    bool? displayed,
    bool? acked,
    Object? fileMetadata = notSpecified,
    Object? errorType = notSpecified,
    Object? warningType = notSpecified,
    bool? isFileUploadNotification,
    bool? isUploading,
    bool? isDownloading,
    Object? originId = notSpecified,
    bool? isRetracted,
    bool? isEdited,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final m = <String, dynamic>{};

    if (body != notSpecified) {
      m['body'] = body as String?;
    }
    if (received != null) {
      m['received'] = boolToInt(received);
    }
    if (displayed != null) {
      m['displayed'] = boolToInt(displayed);
    }
    if (acked != null) {
      m['acked'] = boolToInt(acked);
    }
    if (errorType != notSpecified) {
      m['errorType'] = (errorType as MessageErrorType?)?.value;
    }
    if (warningType != notSpecified) {
      m['warningType'] = warningType as int?;
    }
    if (isFileUploadNotification != null) {
      m['isFileUploadNotification'] = boolToInt(isFileUploadNotification);
    }
    if (isDownloading != null) {
      m['isDownloading'] = boolToInt(isDownloading);
    }
    if (isUploading != null) {
      m['isUploading'] = boolToInt(isUploading);
    }
    if (originId != notSpecified) {
      m['originId'] = originId as String?;
    }
    if (isRetracted != null) {
      m['isRetracted'] = boolToInt(isRetracted);
    }
    if (fileMetadata != notSpecified) {
      m['file_metadata_id'] = (fileMetadata as FileMetadata?)?.id;
    }
    if (isEdited != null) {
      m['isEdited'] = boolToInt(isEdited);
    }
    if (newSid != null) {
      m['sid'] = newSid;
    }

    final updatedMessage = await db.updateAndReturn(
      messagesTable,
      m,
      where: 'sid = ? AND conversationJid = ? AND accountJid = ?',
      whereArgs: [sid, conversationJid, accountJid],
    );

    Message? quotes;
    if (updatedMessage['quote_sid'] != null) {
      quotes = await getMessageBySid(
        updatedMessage['quote_sid']! as String,
        updatedMessage['conversationJid']! as String,
        accountJid,
        queryReactionPreview: false,
      );
    }

    FileMetadata? metadata;
    if (fileMetadata != notSpecified) {
      metadata = fileMetadata as FileMetadata?;
    } else if (updatedMessage['file_metadata_id'] != null) {
      final metadataRaw = (await db.query(
        fileMetadataTable,
        where: 'id = ?',
        whereArgs: [updatedMessage['file_metadata_id']],
        limit: 1,
      ))
          .first;
      metadata = FileMetadata.fromDatabaseJson(metadataRaw);
    }

    final msg = Message.fromDatabaseJson(
      updatedMessage,
      quotes,
      metadata,
      // TODO: How should this work with reactions?
      await GetIt.I
          .get<ReactionsService>()
          .getPreviewReactionsForMessage(sid, conversationJid, accountJid),
    );

    return msg;
  }

  /// Helper function that manages everything related to retracting a message. It
  /// - Replaces all metadata of the message with null values and marks it as retracted
  /// - Modified the conversation, if the retracted message was the newest message
  /// - Update the UI
  ///
  /// [conversationJid] is the bare JID of the conversation this message belongs to.
  /// [originId] is the origin Id of the message that is to be retracted.
  /// [bareSender] is the bare JID of the sender of the retraction message.
  /// [selfRetract] indicates whether the message retraction came from the UI. If true,
  /// then the sender check (see security considerations of XEP-0424) is skipped as
  /// the UI already verifies it.
  Future<void> retractMessage(
    String conversationJid,
    String accountJid,
    String originId,
    String bareSender,
    bool selfRetract,
  ) async {
    final msg = await getMessageByOriginId(
      originId,
      conversationJid,
      accountJid,
      queryReactionPreview: false,
    );

    if (msg == null) {
      _log.finest(
        'Got message retraction for origin Id $originId, but did not find the message',
      );
      return;
    }

    // Check if the retraction was sent by the original sender
    if (!selfRetract) {
      if (JID.fromString(msg.sender).toBare().toString() != bareSender) {
        _log.warning(
          'Received invalid message retraction from $bareSender but its original sender is ${msg.sender}',
        );
        return;
      }
    }

    final isMedia = msg.isMedia;
    final retractedMessage = await updateMessage(
      msg.sid,
      msg.conversationJid,
      accountJid,
      warningType: null,
      errorType: null,
      isRetracted: true,
      body: '',
      fileMetadata: null,
    );
    sendEvent(MessageUpdatedEvent(message: retractedMessage));

    final cs = GetIt.I.get<ConversationService>();
    final conversation =
        await cs.getConversationByJid(conversationJid, accountJid);
    if (conversation != null) {
      if (conversation.lastMessage?.sid == msg.sid) {
        final newConversation = conversation.copyWith(
          lastMessage: retractedMessage,
        );

        cs.setConversation(newConversation);
        sendEvent(
          ConversationUpdatedEvent(
            conversation: newConversation,
          ),
        );

        if (isMedia) {
          // Remove the file
          await GetIt.I.get<FilesService>().removeFileIfNotReferenced(
                msg.fileMetadata!,
              );
        }
      }
    } else {
      _log.warning(
        'Failed to find conversation with conversationJid $conversationJid',
      );
    }
  }

  /// Marks the message with the stanza id [sid] as displayed and sends an
  /// [MessageUpdatedEvent] to the UI. if [sendChatMarker] is true, then
  /// a Chat Marker with <displayed /> is sent to the message's
  /// conversationJid attribute.
  Future<Message> markMessageAsRead(
    String sid,
    String converationJid,
    String accountJid,
    bool sendChatMarker,
  ) async {
    final newMessage = await updateMessage(
      sid,
      converationJid,
      accountJid,
      displayed: true,
    );

    // Tell the UI
    sendEvent(MessageUpdatedEvent(message: newMessage));

    if (sendChatMarker) {
      await GetIt.I.get<XmppService>().sendReadMarker(
            // TODO(Unknown): This is wrong once groupchats are implemented
            newMessage.conversationJid,
            newMessage.originId ?? newMessage.sid,
          );
    }

    return newMessage;
  }
}
