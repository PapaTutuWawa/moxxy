import "dart:convert";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/types/result.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/errors.dart";
import "package:moxxyv2/xmpp/sasl/nonza.dart";

class SaslPlainAuthNonza extends SaslAuthNonza {
  SaslPlainAuthNonza(String username, String password) : super(
    "PLAIN", base64.encode(utf8.encode("\u0000$username\u0000$password"))
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
        return Result(AuthenticationResult.failure, getSaslError(nonza));
      } else if (tag == "success") {
        return Result(AuthenticationResult.success, "");
      }
    } else {
      sendRawXML(SaslPlainAuthNonza(settings.jid.local, settings.password));
      authSent = true;
      return Result(AuthenticationResult.notDone, "");
    }

    return Result(AuthenticationResult.failure, "");
  }
}
