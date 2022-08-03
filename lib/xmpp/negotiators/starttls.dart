import 'package:logging/logging.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

enum _StartTlsState {
  ready,
  requested
}

class StartTLSNonza extends XMLNode {
  StartTLSNonza() : super.xmlns(
    tag: 'starttls',
    xmlns: startTlsXmlns,
  );
}

class StartTlsNegotiator extends XmppFeatureNegotiatorBase {
  
  StartTlsNegotiator()
    : _state = _StartTlsState.ready,
      _log = Logger('StartTlsNegotiator'),
      super(10, true, startTlsXmlns, startTlsNegotiator);
  _StartTlsState _state;

  final Logger _log;

  @override
  Future<void> negotiate(XMLNode nonza) async {
    switch (_state) {
      case _StartTlsState.ready:
        _log.fine('StartTLS is available. Performing StartTLS upgrade...');
        _state = _StartTlsState.requested;
        attributes.sendNonza(StartTLSNonza());
        break;
      case _StartTlsState.requested:
        if (nonza.tag != 'proceed' || nonza.attributes['xmlns'] != startTlsXmlns) {
          _log.severe('Failed to perform StartTLS negotiation');
          state = NegotiatorState.error;
          return;
        }

        _log.fine('Telling the connection to expect a socket closure');
        attributes.setExpectSocketClosure(true);
        
        _log.fine('Securing socket');
        final result = await attributes.getSocket()
          .secure(attributes.getConnectionSettings().jid.domain);
        if (!result) {
          _log.severe('Failed to secure stream');
          state = NegotiatorState.error;
          return;
        }

        _log.fine('Stream is now TLS secured');
        state = NegotiatorState.done;

        _log.fine('Telling the connection to not expect a socket closure anymore');
        attributes.setExpectSocketClosure(false);
        break;
    }
  }

  @override
  void reset() {
    _state = _StartTlsState.ready;

    super.reset();
  }
}
