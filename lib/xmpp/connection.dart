import "dart:io";
import "dart:convert";
import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/sasl/scramsha1.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";

import "package:xml/xml.dart";
import "package:xml/xml_events.dart";
import "package:random_string/random_string.dart";

enum ConnectionState {
  NOT_CONNECTED,
  CONNECTING,
  CONNECTED,
  ERROR
}

class SocketWrapper {
  late final Socket _socket;

  SocketWrapper();

  Future<void> connect(String host, int port) async {
    this._socket = await SecureSocket.connect(host, port, supportedProtocols: [ "xmpp-client" ]);
  }

  Stream<String> asBroadcastStream() {
    return this._socket.cast<List<int>>().transform(utf8.decoder).asBroadcastStream();
  }
  
  void write(Object? object) {
    if (object != null && object is String) {
      print("==> " + object);
    }

    this._socket.write(object);
  }
}

class XmppConnection {
  final ConnectionSettings settings;
  late final SocketWrapper _socket;
  late ConnectionState _connectionState;
  late RoutingState _routingState;
  late final Stream<String> _socketStream;
  late final String domain;
  late final AuthenticationNegotiator _authenticator;
  String _resource = "";
  late final StreamController<XmppEvent> _eventStreamController;

  // NOTE: For mocking
  XmppConnection({ required this.settings, SocketWrapper? socket }) {
    this._connectionState = ConnectionState.NOT_CONNECTED;
    this._routingState = RoutingState.NEGOTIATOR;
    if (socket != null) {
      this._socket = socket;
    } else {
      this._socket = SocketWrapper();
    }

    this._eventStreamController = StreamController();
    this._resource = "";
  }

  Stream<XmppEvent> asBroadcastStream() {
    return this._eventStreamController.stream.asBroadcastStream();
  }
  
  // Just for logging
  void _incomingMiddleware(String data) {
    print("<== " + data);
  }

  void _filterOutStreamBegin(data, EventSink sink) {
    if (data.startsWith("<?xml version='1.0'?>")) {
      data = data.substring(21);
    }

    if (data.startsWith("<stream:stream")) {
      data = data + "</stream:stream>";
    }

    XmlDocument.parse("<root>$data</root>").getElement("root")!.childElements.forEach((element) => sink.add(element));
  }

  void _handleResourceBinding(XmlElement stanza) {
    if (stanza.getAttribute("type") == "result") {
      print("SUCCESS: GOT RESOURCE");

      final bind = stanza.getElement("bind");
      if (bind == null) {
        print("NO BIND ELEMENT");
        return;
      }

      final jid = bind.getElement("jid");
      if (jid == null) {
        print("NO JID");
        return;
      }

      this._resource = jid.innerText.split("/")[1];
      print("----> " + this._resource);

      this._routingState = RoutingState.NORMAL;
      this._connectionState = ConnectionState.CONNECTED;
      this._socket.write(PresenceStanza(
          from: jid.innerText,
          show: PresenceShow.CHAT
        ).toXml());
    }
  }
  
  Future<void> _handleStreamNegotiation(XmlElement nonza) async {
    final streamFeatures = nonza.getElement("stream:features");
    if (streamFeatures == null) {
      print("ERROR: No stream features in stream");
      this._connectionState = ConnectionState.ERROR;
      return;
    }
    print(nonza.name.qualified);
    
    if (streamFeatures.children.length == 0) {
      this._connectionState = ConnectionState.CONNECTED;
      // TODO: Bind resource
      print("bind resource");
      return;
    } else {
      final saslMechanisms = streamFeatures.getElement("mechanisms", namespace: SASL_XMLNS);
      if (saslMechanisms == null) {
        // Authenticated negotiation
        print("AUth negotiation");

        streamFeatures.childElements.forEach((element) {
            final required = element.getElement("required");
            final suffix = required == null ? "false" : "true";
            final tag = element.name.qualified;
            
            print(tag + ": " + suffix);
        });
        
        final required = streamFeatures.childElements.firstWhere((element) {
            return element.getElement("required") != null;
        });

        switch (required.name.qualified) {
          case "bind": {
            this._routingState = RoutingState.RESOURCE_BIND;
            this._socket.write(
              IqStanza(
                id: "aaaaaaaaaa",
                type: StanzaType.SET,
                children: [
                  XMLNode(
                    tag: "bind",
                    attributes: {
                      "xmlns": BIND_XMLNS
                    }
                  )
                ]
              ).toXml()
            );
          }
          break;
        }        
      } else {
        /*
        final bool supportsPlain = saslMechanisms.findElements("mechanism").any(
          (node) => node.innerText == "PLAIN"
        );
        */

        final bool supportsScramSha1 = saslMechanisms.findElements("mechanism").any(
          (node) => node.innerText == "SCRAM-SHA-1"
        );

        if (!supportsScramSha1) {
          print("ERROR: Server does not support SCRAM-SHA-1");
          this._connectionState = ConnectionState.ERROR;
          return;
        }

        print("Proceeding with SASL SCRAM-SHA-1 authentication");
        //this._authenticator = SaslPlainNegotiator(settings: this.settings, send: (data) => this._socket.write(data), sendStreamHeader: this._sendStreamHeader);
        this._authenticator = SaslScramSha1Negotiator(
          settings: this.settings,
          clientNonce: "",
          initialMessageNoGS2: "",
          send: (data) => this._socket.write(data),
          sendStreamHeader: this._sendStreamHeader
        );
        this._routingState = await this._authenticator.next(null);
        // Proceed with PLAIN
      }
    }
    
  }

  void _handleStanza(XmlElement stanza) {
    // TODO: Improve stanza handling
    print("Got " + stanza.name.qualified);

    switch (stanza.name.qualified) {
      case "message": {
        // TODO

        final body = stanza.getElement("body");
        if (body != null) {
          final from = stanza.getAttribute("from")!;
          final sid = stanza.getAttribute("id")!;

          this._eventStreamController.add(
            MessageEvent(
              body: body.innerText,
              fromJid: from,
              sid: sid
            )
          );
        } else {
          // TODO: This will crash if there are no markers
          final chatMarker = stanza.childElements.firstWhere(
            (element) => chatMarkerFromTag(element.name.qualified) != ChatMarkerType.UNKNOWN
          );

          this._eventStreamController.add(
            ChatMarkerEvent(
              type: chatMarkerFromTag(chatMarker.name.qualified),
              sid: stanza.getAttribute("id")!
            )
          );
        } 
      }
      break;
    }
  }

  void handleXmlStream(XmlElement node) async {
    print("(xml) <== " + node.toXmlString());
    final tag = node.name.qualified;

    switch (this._routingState) {
      case RoutingState.NEGOTIATOR: {
        await this._handleStreamNegotiation(node);
      }
      break;
      case RoutingState.AUTHENTICATOR: {
        this._routingState = await this._authenticator.next(node);
      }
      break;
      case RoutingState.RESOURCE_BIND: {
        this._handleResourceBinding(node);
      }
      break;
      case RoutingState.NORMAL: {
        this._handleStanza(node);
      }
      break;
    }
  }

  void _sendStreamHeader() {
    this._socket.write("<?xml version='1.0'?>" + StreamHeaderNonza(this.settings.jid.domain).toXml());
  }
  
  Future<void> connect() async {
    String hostname = this.settings.jid.domain;
    int port = 5222;
    
    if (this.settings.useDirectTLS) {
      final query = await perform0368Lookup(this.settings.jid.domain);

      if (query != null) {
        hostname = query.hostname;
        port = query.port;

        print("Did XEP-0368 lookup. Using ${hostname}:${port.toString()} now.");
      }
    }

    await this._socket.connect(hostname, port);

    this._socketStream = this._socket.asBroadcastStream();
    this._socketStream.listen(this._incomingMiddleware);

    this._socketStream
      .transform(StreamTransformer<String, XmlElement>.fromHandlers(handleData: this._filterOutStreamBegin))
      .forEach(this.handleXmlStream);

    this._connectionState = ConnectionState.CONNECTING;
    this._sendStreamHeader();
  }
}
