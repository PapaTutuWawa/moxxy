import 'dart:async';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/cache.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:synchronized/synchronized.dart';

class MessageService {
  /// Logger
  final Logger _log = Logger('MessageService');

  final LRUCache<String, List<Message>> _messageCache =
      LRUCache(conversationMessagePageCacheSize);
  final Lock _cacheLock = Lock();

  /// Return a list of messages for [jid]. If [olderThan] is true, then all messages are older than [oldestTimestamp], if
  /// specified, or the oldest messages are returned if null. If [olderThan] is false, then message must be newer
  /// than [oldestTimestamp], or the newest messages are returned if null.
  Future<List<Message>> getPaginatedMessagesForJid(
      String jid, bool olderThan, int? oldestTimestamp) async {
    if (olderThan && oldestTimestamp == null) {
      final result = await _cacheLock.synchronized<List<Message>?>(() {
        return _messageCache.getValue(jid);
      });
      if (result != null) return result;
    }

    final page =
        await GetIt.I.get<DatabaseService>().getPaginatedMessagesForJid(
              jid,
              olderThan,
              oldestTimestamp,
            );

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
    bool isMedia,
    String sid,
    bool isFileUploadNotification,
    bool encrypted,
    bool containsNoStore, {
    String? srcUrl,
    String? key,
    String? iv,
    String? encryptionScheme,
    String? mediaUrl,
    String? mediaType,
    String? thumbnailData,
    int? mediaWidth,
    int? mediaHeight,
    String? originId,
    String? quoteId,
    String? filename,
    int? errorType,
    int? warningType,
    Map<String, String>? plaintextHashes,
    Map<String, String>? ciphertextHashes,
    bool isDownloading = false,
    bool isUploading = false,
    int? mediaSize,
    String? stickerPackId,
    String? stickerHashKey,
    int? pseudoMessageType,
    Map<String, dynamic>? pseudoMessageData,
  }) async {
    final msg = await GetIt.I.get<DatabaseService>().addMessageFromData(
          body,
          timestamp,
          sender,
          conversationJid,
          isMedia,
          sid,
          isFileUploadNotification,
          encrypted,
          containsNoStore,
          srcUrl: srcUrl,
          key: key,
          iv: iv,
          encryptionScheme: encryptionScheme,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          thumbnailData: thumbnailData,
          mediaWidth: mediaWidth,
          mediaHeight: mediaHeight,
          originId: originId,
          quoteId: quoteId,
          filename: filename,
          errorType: errorType,
          warningType: warningType,
          plaintextHashes: plaintextHashes,
          ciphertextHashes: ciphertextHashes,
          isUploading: isUploading,
          isDownloading: isDownloading,
          mediaSize: mediaSize,
          stickerPackId: stickerPackId,
          stickerHashKey: stickerHashKey,
          pseudoMessageType: pseudoMessageType,
          pseudoMessageData: pseudoMessageData,
        );

    await _cacheLock.synchronized(() {
      final cachedList = _messageCache.getValue(conversationJid);
      if (cachedList != null) {
        _messageCache.replaceValue(
          conversationJid,
          clampedListPrepend(
            cachedList,
            msg,
            messagePaginationSize,
          ),
        );
      }
    });

    return msg;
  }

  Future<Message?> getMessageByStanzaId(
      String conversationJid, String stanzaId) async {
    return GetIt.I.get<DatabaseService>().getMessageByXmppId(
          stanzaId,
          conversationJid,
          includeOriginId: false,
        );
  }

  Future<Message?> getMessageByStanzaOrOriginId(
      String conversationJid, String id) async {
    return GetIt.I.get<DatabaseService>().getMessageByXmppId(
          id,
          conversationJid,
        );
  }

  Future<Message?> getMessageById(String conversationJid, int id) async {
    return GetIt.I.get<DatabaseService>().getMessageById(
          id,
          conversationJid,
        );
  }

  /// Wrapper around [DatabaseService]'s updateMessage that updates the cache
  Future<Message> updateMessage(
    int id, {
    Object? body = notSpecified,
    Object? mediaUrl = notSpecified,
    Object? mediaType = notSpecified,
    bool? isMedia,
    bool? received,
    bool? displayed,
    bool? acked,
    Object? errorType = notSpecified,
    Object? warningType = notSpecified,
    bool? isFileUploadNotification,
    Object? srcUrl = notSpecified,
    Object? key = notSpecified,
    Object? iv = notSpecified,
    Object? encryptionScheme = notSpecified,
    Object? mediaWidth = notSpecified,
    Object? mediaHeight = notSpecified,
    Object? mediaSize = notSpecified,
    bool? isUploading,
    bool? isDownloading,
    Object? originId = notSpecified,
    Object? sid = notSpecified,
    Object? thumbnailData = notSpecified,
    bool? isRetracted,
    bool? isEdited,
    Object? reactions = notSpecified,
  }) async {
    final msg = await GetIt.I.get<DatabaseService>().updateMessage(
          id,
          body: body,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          received: received,
          displayed: displayed,
          acked: acked,
          errorType: errorType,
          warningType: warningType,
          isFileUploadNotification: isFileUploadNotification,
          srcUrl: srcUrl,
          key: key,
          iv: iv,
          encryptionScheme: encryptionScheme,
          mediaWidth: mediaWidth,
          mediaHeight: mediaHeight,
          mediaSize: mediaSize,
          isUploading: isUploading,
          isDownloading: isDownloading,
          originId: originId,
          sid: sid,
          isRetracted: isRetracted,
          isMedia: isMedia,
          thumbnailData: thumbnailData,
          isEdited: isEdited,
          reactions: reactions,
        );

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
  Future<void> retractMessage(String conversationJid, String originId,
      String bareSender, bool selfRetract) async {
    final msg = await GetIt.I.get<DatabaseService>().getMessageByOriginId(
          originId,
          conversationJid,
        );

    if (msg == null) {
      _log.finest(
          'Got message retraction for origin Id $originId, but did not find the message');
      return;
    }

    // Check if the retraction was sent by the original sender
    if (!selfRetract) {
      if (JID.fromString(msg.sender).toBare().toString() != bareSender) {
        _log.warning(
            'Received invalid message retraction from $bareSender but its original sender is ${msg.sender}');
        return;
      }
    }

    final isMedia = msg.isMedia;
    final mediaUrl = msg.mediaUrl;
    final retractedMessage = await updateMessage(
      msg.id,
      isMedia: false,
      mediaUrl: null,
      mediaType: null,
      warningType: null,
      errorType: null,
      srcUrl: null,
      key: null,
      iv: null,
      encryptionScheme: null,
      mediaWidth: null,
      mediaHeight: null,
      mediaSize: null,
      isRetracted: true,
      thumbnailData: null,
      body: '',
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
          'Failed to find conversation with conversationJid $conversationJid');
    }
  }
}
