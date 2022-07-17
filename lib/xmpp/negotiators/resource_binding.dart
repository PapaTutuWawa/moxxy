import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

class ResourceBindingNegotiator extends XmppFeatureNegotiatorBase {

  ResourceBindingNegotiator() : _requestSent = false, super(0, false, bindXmlns, resourceBindingNegotiator);
  bool _requestSent;

  @override
  Future<void> negotiate(XMLNode nonza) async {
    if (!_requestSent) {
      final stanza = XMLNode.xmlns(
        tag: 'iq',
        xmlns: stanzaXmlns,
        attributes: { 'type': 'set' },
        children: [
          XMLNode.xmlns(
            tag: 'bind',
            xmlns: bindXmlns,
          ),
        ],
      );

      _requestSent = true;
      attributes.sendNonza(stanza);
    } else {
      if (nonza.tag != 'iq' || nonza.attributes['type'] != 'result') {
        state = NegotiatorState.error;
        return;
      }

      final bind = nonza.firstTag('bind')!;
      final jid = bind.firstTag('jid')!;
      final resource = jid.innerText().split('/')[1];

      await attributes.sendEvent(ResourceBindingSuccessEvent(resource: resource));
      state = NegotiatorState.done;
    }
  }
  
  @override
  void reset() {
    _requestSent = false;

    super.reset();
  }
}
