import "dart:async";

import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/negotiator.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/sasl/scramsha1.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

class StreamFeatureNegotiator extends Negotiator {
  XmppConnection connection;

  StreamFeatureNegotiator({ required this.connection });

  Future<RoutingState> next(XMLNode? nonza) async {
    if (nonza!.tag != "stream:stream") {
      // Probably a stream error
      this.connection.sendEvent(StreamErrorEvent(
          // TODO:
          error: nonza.tag
      ));
      
      return RoutingState.ERROR;
    }

    final streamFeatures = nonza.firstTag("stream:features");
    if (streamFeatures == null) {
      print("ERROR: No stream features in stream");
      return RoutingState.ERROR;
    }
    
    if (streamFeatures.children.length == 0) {
      return RoutingState.RESOURCE_BIND;
    } else {
      final saslMechanisms = streamFeatures.firstTag("mechanisms");
      if (saslMechanisms == null) {
        // Authenticated negotiation
        print("Authenticated negotiation");

        streamFeatures.children.forEach((element) {
            final required = element.firstTag("required");
            this.connection.setStreamFeature(element.attributes["xmlns"], required != null);
        });

        return this.connection.streamFeatureSupported(SM_XMLNS) ? RoutingState.STREAM_MANAGEMENT : RoutingState.RESOURCE_BIND;
      } else {
        final bool supportsPlain = saslMechanisms.findTags("mechanism").any(
          (node) => node.innerText() == "PLAIN"
        );
        final bool supportsScramSha1 = saslMechanisms.findTags("mechanism").any(
          (node) => node.innerText() == "SCRAM-SHA-1"
        );
        final bool supportsScramSha256 = saslMechanisms.findTags("mechanism").any(
          (node) => node.innerText() == "SCRAM-SHA-256"
        );

        /*
        if (supportsScramSha256) {
          print("Proceeding with SASL SCRAM-SHA-1 authentication");
          this.connection._authNegotiator = SaslScramSha256Negotiator(
            settings: this.connection.settings,
            clientNonce: "",
            initialMessageNoGS2: "",
            send: (nonza) => this.connection.sendRawXML(nonza),
            sendStreamHeader: this.connection._sendStreamHeader
          );
          return RoutingState.AUTHENTICATOR;
        } else */if (supportsScramSha1) {
          print("Proceeding with SASL SCRAM-SHA-1 authentication");
          this.connection.authNegotiator = SaslScramSha1Negotiator(
            settings: this.connection.settings,
            clientNonce: "",
            initialMessageNoGS2: "",
            send: (nonza) => this.connection.sendRawXML(nonza),
            sendStreamHeader: this.connection.sendStreamHeader
          );
          return RoutingState.AUTHENTICATOR;
        } else if (supportsPlain && this.connection.settings.allowPlainAuth) {
          print("Proceeding with SASL PLAIN authentication");
          this.connection.authNegotiator = SaslPlainNegotiator(
            settings: this.connection.settings,
            send: (nonza) => this.connection.sendRawXML(nonza),
            sendStreamHeader: this.connection.sendStreamHeader
          );
          return RoutingState.AUTHENTICATOR;
        } else {
          print("ERROR: No supported authentication mechanisms");
          return RoutingState.ERROR;
        }
      }
    }
  }
}
