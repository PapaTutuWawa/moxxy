import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';

class ReplyData {

  const ReplyData({
      required this.to,
      required this.id,
      this.start,
      this.end,
  });
  final String to;
  final String id;
  final int? start;
  final int? end;
}

class MessageRepliesManager extends XmppManagerBase {
  @override
  String getName() => 'MessageRepliesManager';

  @override
  String getId() => messageRepliesManager;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'reply',
      tagXmlns: replyXmlns,
      callback: _onMessage,
      // Before the message handler
      priority: -99,
    )
  ];
  
  Future<StanzaHandlerData> _onMessage(Stanza stanza, StanzaHandlerData state) async {
    final reply = stanza.firstTag('reply', xmlns: replyXmlns)!;
    final id = reply.attributes['id']! as String;
    final to = reply.attributes['to']! as String;
    int? start;
    int? end;

    // TODO(Unknown): Maybe extend firstTag to also look for attributes
    final fallback = stanza.firstTag('fallback', xmlns: fallbackXmlns);
    if (fallback != null) {
      final body = fallback.firstTag('body')!;
      start = int.parse(body.attributes['start']! as String);
      end = int.parse(body.attributes['end']! as String);
    }

    return state.copyWith(reply: ReplyData(
        id: id,
        to: to,
        start: start,
        end: end,
    ),);
  }
}
