import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/scram.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

AuthenticationNegotiator? getAuthenticator(List<String> mechanisms, ConnectionSettings settings, void Function(XMLNode, { String? redact}) sendRawXML) {
  // NOTE: Order based on https://wiki.xmpp.org/web/SASL_Authentication_and_SCRAM#Introduction
  if (mechanisms.contains(scramSha512Mechanism)) {
    //print("Proceeding with SASL SCRAM-SHA-512 authentication");
    return SaslScramNegotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML,
      hashType: ScramHashType.sha512
    );
  } else if (mechanisms.contains(scramSha256Mechanism)) {
    //print("Proceeding with SASL SCRAM-SHA-256 authentication");
    return SaslScramNegotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML,
      hashType: ScramHashType.sha256
    );
  } else if (mechanisms.contains(scramSha1Mechanism)) {
    //print("Proceeding with SASL SCRAM-SHA-1 authentication");
    return SaslScramNegotiator(
      settings: settings,
      clientNonce: "",
      initialMessageNoGS2: "",
      sendRawXML: sendRawXML,
      hashType: ScramHashType.sha1
    );
  } else if (settings.allowPlainAuth && mechanisms.contains("PLAIN")) {
    return SaslPlainNegotiator(
      settings: settings,
      sendRawXML: sendRawXML
    );
  } else {
    //print("ERROR: No supported authentication mechanisms");
    return null;
  }
}
