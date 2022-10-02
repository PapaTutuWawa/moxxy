import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';

@immutable
class DelayedDelivery {

  const DelayedDelivery(this.from, this.timestamp);
  final DateTime timestamp;
  final String from;
}

class DelayedDeliveryManager extends XmppManagerBase {

  @override
  String getId() => delayedDeliveryManager;

  @override
  String getName() => 'DelayedDeliveryManager';

  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      callback: _onIncomingMessage,
      priority: 200,
    ),
  ];

  Future<StanzaHandlerData> _onIncomingMessage(Stanza stanza, StanzaHandlerData state) async {
    final delay = stanza.firstTag('delay', xmlns: delayedDeliveryXmlns);
    if (delay == null) return state;

    return state.copyWith(
      delayedDelivery: DelayedDelivery(
        delay.attributes['from']! as String,
        DateTime.parse(delay.attributes['stamp']! as String),
      ),
    );
  }
}
