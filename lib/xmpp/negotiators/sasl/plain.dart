import "dart:convert";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/negotiators/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";
import "package:moxxyv2/xmpp/negotiators/sasl/negotiator.dart";
import "package:moxxyv2/xmpp/negotiators/sasl/nonza.dart";

class SaslPlainAuthNonza extends SaslAuthNonza {
  SaslPlainAuthNonza(String username, String password) : super(
    "PLAIN", base64.encode(utf8.encode("\u0000$username\u0000$password"))
  );
}

class SaslPlainNegotiator extends SaslNegotiator {
  bool _authSent;

  SaslPlainNegotiator() : _authSent = false, super(0, saslPlainNegotiator, "PLAIN");

  @override
  bool matchesFeature(List<XMLNode> features) {
    if (!attributes.getConnectionSettings().allowPlainAuth) return false;
    
    return super.matchesFeature(features);
  }

  @override
  Future<void> negotiate(XMLNode nonza) async {
    if (!_authSent) {
      final settings = attributes.getConnectionSettings();
      attributes.sendNonza(
        // TODO: Redact
        SaslPlainAuthNonza(settings.jid.local, settings.password)
      );
      _authSent = true;
    } else {
      final tag = nonza.tag;
      if (tag == "success") {
        state = NegotiatorState.done;
      } else {
        state = NegotiatorState.error;
      }
    }
  }

  @override
  void reset() {
    _authSent = false;

    super.reset();
  }
}
