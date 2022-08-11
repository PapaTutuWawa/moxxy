import 'dart:collection';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database.dart';
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
    String from,
    String conversationJid,
    bool sent,
    bool isMedia,
    String sid,
    {
      String? srcUrl,
      String? mediaUrl,
      String? mediaType,
      String? thumbnailData,
      String? thumbnailDimensions,
      String? originId,
      String? quoteId,
    }
  ) async {
    final msg = await GetIt.I.get<DatabaseService>().addMessageFromData(
      body,
      timestamp,
      from,
      conversationJid,
      sent,
      isMedia,
      sid,
      srcUrl: srcUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailData: thumbnailData,
      thumbnailDimensions: thumbnailDimensions,
      originId: originId,
      quoteId: quoteId,
    );

    // Only update the cache if the conversation already has been loaded. This prevents
    // us from accidentally not loading the conversation afterwards.
    if (_messageCache.containsKey(conversationJid)) {
      _messageCache[conversationJid] = _messageCache[conversationJid]!..add(msg);
    }

    return msg;
  }

  /// Wrapper around [DatabaseService]'s updateMessage that updates the cache
  Future<Message> updateMessage(int id, {
      String? mediaUrl,
      String? mediaType,
      bool? received,
      bool? displayed,
      bool? acked,
      int? errorType,
  }) async {
    final newMessage = await GetIt.I.get<DatabaseService>().updateMessage(
      id,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      received: received,
      displayed: displayed,
      acked: acked,
      errorType: errorType,
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
