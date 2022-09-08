import 'dart:collection';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/helpers.dart';
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
    {
      String? srcUrl,
      String? mediaUrl,
      String? mediaType,
      String? thumbnailData,
      int? mediaWidth,
      int? mediaHeight,
      String? originId,
      String? quoteId,
      String? filename,
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
      srcUrl: srcUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailData: thumbnailData,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      originId: originId,
      quoteId: quoteId,
      filename: filename,
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
  
  /// Wrapper around [DatabaseService]'s updateMessage that updates the cache
  Future<Message> updateMessage(int id, {
    String? mediaUrl,
    String? mediaType,
    bool? received,
    bool? displayed,
    bool? acked,
    int? errorType,
    bool? isFileUploadNotification,
    String? srcUrl,
    int? mediaWidth,
    int? mediaHeight,
  }) async {
    final newMessage = await GetIt.I.get<DatabaseService>().updateMessage(
      id,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      received: received,
      displayed: displayed,
      acked: acked,
      errorType: errorType,
      isFileUploadNotification: isFileUploadNotification,
      srcUrl: srcUrl,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
    );

    if (_messageCache.containsKey(newMessage.conversationJid)) {
      _messageCache[newMessage.conversationJid] = _messageCache[newMessage.conversationJid]!.map((m) {
          if (m.id == newMessage.id) return newMessage;

          return m;
      }).toList();
    }
    
    return newMessage;
  }
}
