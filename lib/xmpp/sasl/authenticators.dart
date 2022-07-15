import "package:moxxyv2/xmpp/negotiators/negotiator.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/scram.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class SaslAuthenticationNegotiator extends XmppFeatureNegotiatorBase {
  AuthenticationNegotiator? _negotiator;

  SaslAuthenticationNegotiator() : super(0, true, saslXmlns);

  void _updateState(AuthenticationResult result) {
    switch (result) {
      case AuthenticationResult.failure:
        state = NegotiatorState.error;
        break;
      case AuthenticationResult.success: 
        state = NegotiatorState.done;
        break;
      case AuthenticationResult.notDone: 
        state = NegotiatorState.ready;
        break;
    }
  }
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
    if (_negotiator != null) {
      final result = await _negotiator!.next(nonza);
      _updateState(result.getState());
    } else {
      final mechanismsElement = nonza.firstTag("mechanisms", xmlns: saslXmlns)!;
      final mechanisms = mechanismsElement.children.map((node) => node.text!).toList();
      final settings = attributes.getConnectionSettings();
      
      if (mechanisms.contains(scramSha512Mechanism)) {
        _negotiator = SaslScramNegotiator(
          settings: settings,
          clientNonce: "",
          initialMessageNoGS2: "",
          // TODO
          sendRawXML: (XMLNode node, {String? redact}) => attributes.sendNonza(node),
          hashType: ScramHashType.sha512,
        );
      } else if (mechanisms.contains(scramSha256Mechanism)) {
        _negotiator = SaslScramNegotiator(
          settings: settings,
          clientNonce: "",
          initialMessageNoGS2: "",
          // TODO
          sendRawXML: (XMLNode node, {String? redact}) => attributes.sendNonza(node),
          hashType: ScramHashType.sha256,
        );
      } else if (mechanisms.contains(scramSha1Mechanism)) {
        _negotiator = SaslScramNegotiator(
          settings: settings,
          clientNonce: "",
          initialMessageNoGS2: "",
          // TODO
          sendRawXML: (XMLNode node, {String? redact}) => attributes.sendNonza(node),
          hashType: ScramHashType.sha1,
        );
      } else if (settings.allowPlainAuth && mechanisms.contains("PLAIN")) {
        _negotiator = SaslPlainNegotiator(
          settings: settings,
          // TODO
          sendRawXML: (XMLNode node, {String? redact}) => attributes.sendNonza(node),
        );
      } else {
        state = NegotiatorState.error;
        return;
      }

      final result = await _negotiator!.next(null);
      _updateState(result.getState());
    }
  }

  @override
  void reset() {
    _negotiator = null;

    super.reset();
  }
}
