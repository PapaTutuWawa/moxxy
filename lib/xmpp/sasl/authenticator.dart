import "package:moxxyv2/xmpp/routing.dart";

import "package:moxxyv2/xmpp/stringxml.dart";

enum AuthenticationResult {
  SUCCESS,
  FAILURE,
  NOT_DONE
}

abstract class AuthenticationNegotiator {
  // The function **MUST** send the initial <auth /> nonza when called with null
  Future<AuthenticationResult> next(XMLNode? nonza);
}
