import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/cache.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:synchronized/synchronized.dart';

class MessageService {
  /// Logger
  final Logger _log = Logger('MessageService');

  final LRUCache<String, List<Message>> _messageCache =
      LRUCache(conversationMessagePageCacheSize);
  final Lock _cacheLock = Lock();

  Future<Message?> getMessageById(int id, String conversationJid) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final messagesRaw = await db.query(
      messagesTable,
      where: 'id = ? AND conversationJid = ?',
      whereArgs: [id, conversationJid],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;

    // Load the file metadata, if available
    FileMetadata? fm;
    if (msg['file_metadata_id'] != null) {
      final rawFm = (await db.query(
        fileMetadataTable,
        where: 'id = ?',
        whereArgs: [msg['file_metadata_id']],
        limit: 1,
      ))
          .first;
      fm = FileMetadata.fromDatabaseJson(rawFm);
    }

    return Message.fromDatabaseJson(msg, null, fm);
  }

  Future<Message?> getMessageByXmppId(
    String id,
    String conversationJid, {
    bool includeOriginId = true,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    final idQuery = includeOriginId ? '(sid = ? OR originId = ?)' : 'sid = ?';
    final messagesRaw = await db.query(
      messagesTable,
      where: 'conversationJid = ? AND $idQuery',
      whereArgs: [
        conversationJid,
        if (includeOriginId) id,
        id,
      ],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;

    FileMetadata? fm;
    if (msg['file_metadata_id'] != null) {
      final rawFm = (await db.query(
        fileMetadataTable,
        where: 'id = ?',
        whereArgs: [msg['file_metadata_id']],
        limit: 1,
      ))
          .first;
      fm = FileMetadata.fromDatabaseJson(rawFm);
    }

    return Message.fromDatabaseJson(msg, null, fm);
  }

  /// Return a list of messages for [jid]. If [olderThan] is true, then all messages are older than [oldestTimestamp], if
  /// specified, or the oldest messages are returned if null. If [olderThan] is false, then message must be newer
  /// than [oldestTimestamp], or the newest messages are returned if null.
  Future<List<Message>> getPaginatedMessagesForJid(
    String jid,
    bool olderThan,
    int? oldestTimestamp,
  ) async {
    if (olderThan && oldestTimestamp == null) {
      final result = await _cacheLock.synchronized<List<Message>?>(() {
        return _messageCache.getValue(jid);
      });
      if (result != null) return result;
    }

    final db = GetIt.I.get<DatabaseService>().database;
    final comparator = olderThan ? '<' : '>';
    final query = oldestTimestamp != null
        ? 'conversationJid = ? AND timestamp $comparator ?'
        : 'conversationJid = ?';
    final rawMessages = await db.rawQuery(
      // LEFT JOIN $messagesTable quote ON msg.quote_id = quote.id
      '''
SELECT
  msg.*,
  quote.id AS quote_id,
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
  quote.quote_id AS quote_quote_id,
  quote.file_metadata_id AS quote_file_metadata_id,
  quote.isDownloading AS quote_isDownloading,
  quote.isUploading AS quote_isUploading,
  quote.isRetracted AS quote_isRetracted,
  quote.isEdited AS quote_isEdited,
  quote.reactions AS quote_reactions,
  quote.containsNoStore AS quote_containsNoStore,
  quote.stickerPackId AS quote_stickerPackId,
  quote.pseudoMessageType AS quote_pseudoMessageType,
  quote.pseudoMessageData AS quote_pseudoMessageData,
  fm.id as fm_id,
  fm.path as fm_path,
  fm.sourceUrl as fm_sourceUrl,
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
  LEFT JOIN $messagesTable quote ON msg.quote_id = quote.id;
      ''',
      [
        jid,
        if (oldestTimestamp != null) oldestTimestamp,
      ],
    );

    final page = List<Message>.empty(growable: true);
    for (final m in rawMessages) {
      if (m.isEmpty) {
        continue;
      }

      Message? quotes;
      if (m['quote_id'] != null) {
        final rawQuote = Map<String, dynamic>.fromEntries(
          m.entries.where((entry) => entry.key.startsWith('quote_')).map(
                (entry) => MapEntry<String, dynamic>(
                  entry.key.substring(6),
                  entry.value,
                ),
              ),
        );

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

        quotes = Message.fromDatabaseJson(rawQuote, null, quoteFm);
      }

      FileMetadata? fm;
      if (m['file_metadata_id'] != null) {
        fm = FileMetadata.fromDatabaseJson(
          Map<String, Object?>.fromEntries(
            m.entries.where((entry) => entry.key.startsWith('fm_')).map(
                  (entry) => MapEntry<String, Object?>(
                    entry.key.substring(3),
                    entry.value,
                  ),
                ),
          ),
        );
      }

      page.add(Message.fromDatabaseJson(m, quotes, fm));
    }

    if (olderThan && oldestTimestamp == null) {
      await _cacheLock.synchronized(() {
        _messageCache.cache(
          jid,
          page,
        );
      });
    }

    return page;
  }

  /// Wrapper around [DatabaseService]'s addMessageFromData that updates the cache.
  Future<Message> addMessageFromData(
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
    int? errorType,
    int? warningType,
    bool isDownloading = false,
    bool isUploading = false,
    String? stickerPackId,
    int? pseudoMessageType,
    Map<String, dynamic>? pseudoMessageData,
    bool received = false,
    bool displayed = false,
  }) async {
    final db = GetIt.I.get<DatabaseService>().database;
    var m = Message(
      sender,
      body,
      timestamp,
      sid,
      -1,
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
      final quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes == null) {
        _log.warning('Failed to add quote for message with id $quoteId');
      } else {
        m = m.copyWith(quotes: quotes);
      }
    }

    m = m.copyWith(
      id: await db.insert(messagesTable, m.toDatabaseJson()),
    );

    await _cacheLock.synchronized(() {
      final cachedList = _messageCache.getValue(conversationJid);
      if (cachedList != null) {
        _messageCache.replaceValue(
          conversationJid,
          clampedListPrepend(
            cachedList,
            m,
            messagePaginationSize,
          ),
        );
      }
    });

    return m;
  }

  Future<Message?> getMessageByStanzaId(
    String conversationJid,
    String stanzaId,
  ) async {
    return getMessageByXmppId(
      stanzaId,
      conversationJid,
      includeOriginId: false,
    );
  }

  Future<Message?> getMessageByStanzaOrOriginId(
    String conversationJid,
    String id,
  ) async {
    return getMessageByXmppId(
      id,
      conversationJid,
    );
  }

  /// Wrapper around [DatabaseService]'s updateMessage that updates the cache
  Future<Message> updateMessage(
    int id, {
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
    Object? sid = notSpecified,
    bool? isRetracted,
    bool? isEdited,
    Object? reactions = notSpecified,
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
      m['errorType'] = errorType as int?;
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
    if (sid != notSpecified) {
      m['sid'] = sid as String?;
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
    if (reactions != notSpecified) {
      assert(reactions != null, 'Cannot set reactions to null');
      // TODO(PapaTutuWawa): Replace with a new table
      m['reactions'] = jsonEncode(
        (reactions! as List<Reaction>).map((r) => r.toJson()).toList(),
      );
    }

    final updatedMessage = await db.updateAndReturn(
      messagesTable,
      m,
      where: 'id = ?',
      whereArgs: [id],
    );

    Message? quotes;
    if (updatedMessage['quote_id'] != null) {
      quotes = await getMessageById(
        updatedMessage['quote_id']! as int,
        updatedMessage['conversationJid']! as String,
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

    final msg = Message.fromDatabaseJson(updatedMessage, quotes, metadata);

    await _cacheLock.synchronized(() {
      final page = _messageCache.getValue(msg.conversationJid);
      if (page != null) {
        _messageCache.replaceValue(
          msg.conversationJid,
          page.map((m) {
            if (m.id == msg.id) {
              return msg;
            }

            return m;
          }).toList(),
        );
      }
    });

    return msg;
  }

  /// Helper function that manages everything related to retracting a message. It
  /// - Replaces all metadata of the message with null values and marks it as retracted
  /// - Modified the conversation, if the retracted message was the newest message
  /// - Remove the SharedMedium from the database, if one referenced the retracted message
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
    String originId,
    String bareSender,
    bool selfRetract,
  ) async {
    final msg = await getMessageByXmppId(
      originId,
      conversationJid,
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
    final mediaUrl = msg.fileMetadata?.path;
    final retractedMessage = await updateMessage(
      msg.id,
      warningType: null,
      errorType: null,
      isRetracted: true,
      body: '',
      // TODO(Unknown): Can we delete the file?
      fileMetadata: null,
    );
    sendEvent(MessageUpdatedEvent(message: retractedMessage));

    final cs = GetIt.I.get<ConversationService>();
    final conversation = await cs.getConversationByJid(conversationJid);
    if (conversation != null) {
      if (conversation.lastMessage?.id == msg.id) {
        var newConversation = conversation.copyWith(
          lastMessage: retractedMessage,
        );

        if (isMedia) {
          await GetIt.I
              .get<DatabaseService>()
              .removeSharedMediumByMessageId(msg.id);

          // TODO(Unknown): Technically, we would have to then load 1 shared media
          //                item from the database to, if possible, fill the list
          //                back up to 8 items.
          newConversation = newConversation.copyWith(
            sharedMedia:
                newConversation.sharedMedia.where((SharedMedium medium) {
              return medium.messageId != msg.id;
            }).toList(),
          );

          // Delete the file if we downloaded it
          if (mediaUrl != null) {
            final file = File(mediaUrl);
            if (file.existsSync()) {
              unawaited(file.delete());
            }
          }
        }

        cs.setConversation(newConversation);
        sendEvent(
          ConversationUpdatedEvent(
            conversation: newConversation,
          ),
        );
      }
    } else {
      _log.warning(
        'Failed to find conversation with conversationJid $conversationJid',
      );
    }
  }
}
