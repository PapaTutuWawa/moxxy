import "dart:async";

import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/negotiator.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/xeps/0198.dart";

enum SMState {
  PRE_NEGOTIATION,
  RESUME_SENT,
  ENABLE_SENT
}

class StreamManagementNegotiator extends Negotiator {
  SMState _state;
  XmppConnection connection;

  StreamManagementNegotiator({ required this.connection }) : _state = SMState.PRE_NEGOTIATION;

  Future<RoutingState> next(XMLNode? nonza) async {
    switch (this._state) {
      case SMState.PRE_NEGOTIATION: {
        if (this.connection.streamFeatureSupported(SM_XMLNS)) {
          if (this.connection.settings.streamResumptionId != null) {
            // Try to resume the stream
            // TODO: The last server stanza
            this.connection.sendRawXML(StreamManagementResumeNonza(this.connection.settings.streamResumptionId!, 4));
            this._state = SMState.RESUME_SENT;
          } else {
            // Try to enable the stream
            this.connection.sendRawXML(StreamManagementEnableNonza());
            this._state = SMState.ENABLE_SENT;
          }

          return RoutingState.STREAM_MANAGEMENT;
        } else {
          return RoutingState.NORMAL;
        }
      }
      break;
      case SMState.RESUME_SENT: {
        if (nonza!.attributes["xmlns"] != SM_XMLNS) {
          print("Unexpected nonza received: " + nonza.toXml());
          return RoutingState.RESOURCE_BIND;
        }

        if (nonza.tag == "failed") {
          print("Stream resumption failed. Trying to enable after resource binding...");
          //this.connection.sendRawXML(StreamManagementEnableNonza());

          this._state = SMState.ENABLE_SENT;
          return RoutingState.RESOURCE_BIND;
        } else if (nonza.tag == "resumed") {
          print("Stream resumption successful.");
          return RoutingState.NORMAL;
        } else {
          print("Unexpected SM nonza received: " + nonza.tag);
          return RoutingState.RESOURCE_BIND;
        }
      }
      break;
      case SMState.ENABLE_SENT: {
         if (nonza!.attributes["xmlns"] != SM_XMLNS) {
          print("Unexpected nonza received: " + nonza.toXml());
          return RoutingState.NORMAL;
        }

        if (nonza.tag == "enabled") {
          print("Enabling Stream Management successful.");
          String id = "";
          if (nonza.attributes["resume"] == "true" || nonza.attributes["resume"] == "1") {
            print("Stream resumption supported...");
            id = nonza.attributes["id"]!;

            this.connection.sendEvent(StreamResumptionEvent(id: id));
          } else {
            print("Stream resumption not supported...");
          }

          this.connection.streamManager = StreamManager(connection: this.connection, streamResumptionId: id);
        } else if (nonza.tag == "failed") {
          print("Enabling Stream Management failed");
        } else {
          print("Unexpected SM nonza received: " + nonza.tag);
        }

        return RoutingState.NORMAL;
      }
      break;
    }
  }
}
