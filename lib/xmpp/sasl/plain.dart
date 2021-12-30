import "dart:convert";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

class SaslPlainAuthNonza extends XMLNode {
  SaslPlainAuthNonza(String username, String password) : super(
    tag: "auth",
    attributes: {
      "xmlns": SASL_XMLNS,
      "mechanism": "PLAIN" 
    },
    text: base64.encode(utf8.encode("\u0000$username\u0000$password"))
  );
}

class SaslPlainNegotiator extends AuthenticationNegotiator {
  bool authSent = false;
  final ConnectionSettings settings;

  SaslPlainNegotiator({ required this.settings, required void Function(String) send, required void Function() sendStreamHeader }) : super(send: send, sendStreamHeader: sendStreamHeader);
  
  Future<RoutingState> next(XMLNode? nonza) async {
    if (authSent) {
      final tag = nonza!.tag;
      if (tag == "failure") {
        print("SASL failure");
        return RoutingState.ERROR;
      } else if (tag == "success") {
        print("SASL success");
        this.sendStreamHeader();
        return RoutingState.NEGOTIATOR;
      }
    } else {
      this.send(SaslPlainAuthNonza(this.settings.jid.local, this.settings.password).toXml());
      this.authSent = true;
      return RoutingState.AUTHENTICATOR;
    }

    return RoutingState.ERROR;
  }
}
