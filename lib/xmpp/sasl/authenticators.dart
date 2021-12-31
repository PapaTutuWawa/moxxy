import "dart:collection";

import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/scramsha1.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

AuthenticationNegotiator? getAuthenticator(List<String> mechanisms, ConnectionSettings settings, void Function(XMLNode) sendRawXML) {
  if (mechanisms.indexOf("SCRAM-SHA-1") != -1) {
    print("Proceeding with SASL SCRAM-SHA-1 authentication");
    return SaslScramSha1Negotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML
    );
  } else if (settings.allowPlainAuth && mechanisms.indexOf("PLAIN") != -1) {
    return SaslPlainNegotiator(
      settings: settings,
      sendRawXML: sendRawXML
    );
  } else {
    print("ERROR: No supported authentication mechanisms");
    return null;
  }
}
