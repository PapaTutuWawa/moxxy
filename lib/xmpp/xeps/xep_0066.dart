import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';

/// A data class representing the jabber:x:oob tag.
class OOBData {

  const OOBData({ this.url, this.desc });
  final String? url;
  final String? desc;
}

class OOBManager extends XmppManagerBase {
  @override
  String getName() => 'OOBName';

  @override
  String getId() => oobManager;

  @override
  List<String> getDiscoFeatures() => [ oobDataXmlns ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'x',
      tagXmlns: oobDataXmlns,
      callback: _onMessage,
      // Before the message manager
      priority: -99,
    )
  ];

  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final x = message.firstTag('x', xmlns: oobDataXmlns)!;
    final url = x.firstTag('url');
    final desc = x.firstTag('desc');

    return state.copyWith(
      oob: OOBData(
        url: url?.innerText(),
        desc: desc?.innerText(),
      ),
    );
  }
}
