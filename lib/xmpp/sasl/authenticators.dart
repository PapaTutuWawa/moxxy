import "dart:collection";

import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/scram.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

AuthenticationNegotiator? getAuthenticator(List<String> mechanisms, ConnectionSettings settings, void Function(XMLNode) sendRawXML) {
  // NOTE: Order based on https://wiki.xmpp.org/web/SASL_Authentication_and_SCRAM#Introduction
  if (mechanisms.indexOf(SCRAM_SHA512_MECHANISM) != -1) {
    print("Proceeding with SASL SCRAM-SHA-512 authentication");
    return SaslScramNegotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML,
      hashType: ScramHashType.SHA512
    );
  } else if (mechanisms.indexOf(SCRAM_SHA256_MECHANISM) != -1) {
    print("Proceeding with SASL SCRAM-SHA-256 authentication");
    return SaslScramNegotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML,
      hashType: ScramHashType.SHA256
    );
  } else if (mechanisms.indexOf(SCRAM_SHA1_MECHANISM) != -1) {
    print("Proceeding with SASL SCRAM-SHA-1 authentication");
    return SaslScramNegotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML,
      hashType: ScramHashType.SHA1
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
