import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';

class MessageService {
  MessageService() : _messageCache = HashMap(), _log = Logger('MessageService');
  final HashMap<String, List<Message>> _messageCache;
  final Logger _log;

  /// Returns the messages for [jid], either from cache or from the database.
  Future<List<Message>> getMessagesForJid(String jid) async {
    if (!_messageCache.containsKey(jid)) {
      _messageCache[jid] = await GetIt.I.get<DatabaseService>().loadMessagesForJid(jid);
    }

    final messages = _messageCache[jid];
    if (messages == null) {
      _log.warning('No messages found for $jid. Returning [].');
      return [];
    }

    return messages;
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
    {
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
    }
  ) async {
    final msg = await GetIt.I.get<DatabaseService>().addMessageFromData(
      body,
      timestamp,
      sender,
      conversationJid,
      isMedia,
      sid,
      isFileUploadNotification,
      encrypted,
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
    );

    // Only update the cache if the conversation already has been loaded. This prevents
    // us from accidentally not loading the conversation afterwards.
    if (_messageCache.containsKey(conversationJid)) {
      _messageCache[conversationJid] = _messageCache[conversationJid]!..add(msg);
    }

    return msg;
  }

  Future<Message?> getMessageByStanzaId(String conversationJid, String stanzaId) async {
    if (!_messageCache.containsKey(conversationJid)) {
      await getMessagesForJid(conversationJid);
    }
    
    return firstWhereOrNull(
      _messageCache[conversationJid]!,
      (message) => message.sid == stanzaId,
    );
  }

  Future<Message?> getMessageById(String conversationJid, int id) async {
    if (!_messageCache.containsKey(conversationJid)) {
      await getMessagesForJid(conversationJid);
    }

    return firstWhereOrNull(
      _messageCache[conversationJid]!,
      (message) => message.id == id,
    );
  }

  /// Wrapper around [DatabaseService]'s updateMessage that updates the cache
  Future<Message> updateMessage(int id, {
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
  }) async {
    final newMessage = await GetIt.I.get<DatabaseService>().updateMessage(
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
    );

    if (_messageCache.containsKey(newMessage.conversationJid)) {
      _messageCache[newMessage.conversationJid] = _messageCache[newMessage.conversationJid]!.map((m) {
        if (m.id == newMessage.id) return newMessage;

        return m;
      }).toList();
    }
    
    return newMessage;
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
  Future<void> retractMessage(String conversationJid, String originId, String bareSender, bool selfRetract) async {
    final msg = await GetIt.I.get<DatabaseService>().getMessageByOriginId(
      originId,
      conversationJid,
    );

    if (msg == null) {
      _log.finest('Got message retraction for origin Id $originId, but did not find the message');
      return;
    }

    // Check if the retraction was sent by the original sender
    if (!selfRetract) {
      if (JID.fromString(msg.sender).toBare().toString() != bareSender) {
        _log.warning('Received invalid message retraction from $bareSender but its original sender is ${msg.sender}');
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
          await GetIt.I.get<DatabaseService>().removeSharedMediumByMessageId(msg.id);

          newConversation = newConversation.copyWith(
            sharedMedia: newConversation.sharedMedia.where((SharedMedium medium) {
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
      _log.warning('Failed to find conversation with conversationJid $conversationJid');
    }
  }
}
