import "dart:async";

import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/negotiator.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

class ResourceBindingNegotiator extends Negotiator {
  XmppConnection connection;
  bool attemptSMEnable;

  ResourceBindingNegotiator({ required this.connection }) : attemptSMEnable = false;

  void setAttemptSMEnable(bool enable) {
    this.attemptSMEnable = enable;
  }
  
  Future<RoutingState> next(XMLNode? stanza) async {
    if (stanza!.attributes["type"] == "result") {
      print("SUCCESS: GOT RESOURCE");

      final bind = stanza.firstTag("bind");
      if (bind == null) {
        print("NO BIND ELEMENT");
        return RoutingState.ERROR;
      }

      final jid = bind.firstTag("jid");
      if (jid == null) {
        print("NO JID");
        return RoutingState.ERROR;
      }

      this.connection.setResource(jid.innerText().split("/")[1]);
      //print("----> " + this.connection._resource);

      if (this.attemptSMEnable) {
        return RoutingState.STREAM_MANAGEMENT;
      } 
    }

    return RoutingState.NORMAL;
  }
}
