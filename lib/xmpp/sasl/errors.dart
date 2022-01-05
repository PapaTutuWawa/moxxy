import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";

// See https://xmpp.org/rfcs/rfc6120.html#toc
const SASL_ERROR_ABORTED = "aborted";
const SASL_ERROR_ACCOUNT_DISABLED = "account-disabled";
const SASL_ERROR_CREDENTIALS_EXPIRED = "credentials-expired";
const SASL_ERROR_ENCRYPTION_REQUIRED = "encryption-required";
const SASL_ERROR_INCORRECT_ENCODING = "incorrect-encoding";
const SASL_ERROR_INVALID_AUTHZID = "invalid-authzid";
const SASL_ERROR_INVALID_MECHANISM = "invalid-mechanism";
const SASL_ERROR_MALFORMED_REQUEST = "malformed-request";
const SASL_ERROR_MECHANISM_TOO_WEAK = "mechanism-too-weak";
const SASL_ERROR_NOT_AUTHORIZED = "not-authorized";
const SASL_ERROR_TEMPORARY_AUTH_FAILURE = "temporary-auth-failure";

String getSaslError(XMLNode nonza) {
  // TODO:
  if (nonza.tag != "failure" || nonza.attributes["xmlns"] != SASL_XMLNS) return "";
  if (nonza.children.isEmpty) return "";

  return nonza.children[0].tag;
}
