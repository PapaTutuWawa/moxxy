import "package:moxxyv2/xmpp/routing.dart";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

abstract class Negotiator {
  Future<RoutingState> next(XMLNode? nonza);
}
