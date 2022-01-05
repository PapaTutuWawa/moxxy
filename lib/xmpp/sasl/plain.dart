import "dart:convert";

import "package:moxxyv2/types/result.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/errors.dart";
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
  void Function(XMLNode) sendRawXML;
  bool authSent = false;
  final ConnectionSettings settings;

  SaslPlainNegotiator({ required this.settings, required this.sendRawXML });

  @override
  Future<Result<AuthenticationResult, String>> next(XMLNode? nonza) async {
    if (authSent) {
      final tag = nonza!.tag;
      if (tag == "failure") {
        print("SASL failure");
        return Result(AuthenticationResult.FAILURE, getSaslError(nonza));
      } else if (tag == "success") {
        print("SASL success");
        return Result(AuthenticationResult.SUCCESS, "");
      }
    } else {
      this.sendRawXML(SaslPlainAuthNonza(this.settings.jid.local, this.settings.password));
      this.authSent = true;
      return Result(AuthenticationResult.NOT_DONE, "");
    }

    return Result(AuthenticationResult.FAILURE, "");
  }
}
