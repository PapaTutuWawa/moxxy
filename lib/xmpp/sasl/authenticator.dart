import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/types/result.dart";

enum AuthenticationResult {
  success,
  failure,
  notDone
}

abstract class AuthenticationNegotiator {
  /// The function **MUST** send the initial <auth /> nonza when called with null
  Future<Result<AuthenticationResult, String>> next(XMLNode? nonza);
}
