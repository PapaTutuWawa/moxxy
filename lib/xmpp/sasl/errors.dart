import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

// See https://xmpp.org/rfcs/rfc6120.html#toc
const saslErrorAborted = "aborted";
const saslErrorAccountDisabled = "account-disabled";
const saslErrorCredentialsExpired = "credentials-expired";
const saslErrorEncryptionRequired = "encryption-required";
const saslErrorIncorrectEncoding = "incorrect-encoding";
const saslErrorInvalidAuthZID = "invalid-authzid";
const saslErrorInvalidMechanism = "invalid-mechanism";
const saslErrorMalformedRequest = "malformed-request";
const saslErrorMechanismTooWeak = "mechanism-too-weak";
const saslErrorNotAuthorized = "not-authorized";
const saslErrorTempoaryAuthFailure = "temporary-auth-failure";

String getSaslError(XMLNode nonza) {
  // TODO:
  if (nonza.tag != "failure" || nonza.attributes["xmlns"] != saslXmlns) return "";
  if (nonza.children.isEmpty) return "";

  return nonza.children[0].tag;
}
