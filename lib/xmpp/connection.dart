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

class ConnectionStateChangedEvent extends XmppEvent {
  final ConnectionState state;

  ConnectionStateChangedEvent({ required this.state });
}

class StreamErrorEvent extends XmppEvent {
  final String error;

  StreamErrorEvent({ required this.error });
}

// TODO: Implement a send queue
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
  final Map<String, Completer<XMLNode>> _awaitingResponse = Map();

  Future<XMLNode> sendStanza(Stanza stanza) {
    if (stanza.id == null) {
      stanza = stanza.copyWith(id: randomAlphaNumeric(20));
    }

    this._awaitingResponse[stanza.id!] = Completer();
    this._socket.write(stanza.toXml());
    return this._awaitingResponse[stanza.id!]!.future;
  }
  
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

  void _setConnectionState(ConnectionState state) {
    this._connectionState = state;
    this._eventStreamController.add(ConnectionStateChangedEvent(state: state));
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
    } else {
      if (data.endsWith("</stream:stream>")) {
        // TODO: Maybe destroy the stream
        data = data.substring(0, data.length - 16);
      }
    } 

    XmlDocument
      .parse("<root>$data</root>")
      .getElement("root")!
      .childElements
      .forEach((element) => sink.add(XMLNode.fromXmlElement(element)));
  }

  void _handleResourceBinding(XMLNode stanza) {
    if (stanza.attributes["type"] == "result") {
      print("SUCCESS: GOT RESOURCE");

      final bind = stanza.firstTag("bind");
      if (bind == null) {
        print("NO BIND ELEMENT");
        return;
      }

      final jid = bind.firstTag("jid");
      if (jid == null) {
        print("NO JID");
        return;
      }

      this._resource = jid.innerText().split("/")[1];
      print("----> " + this._resource);

      this._routingState = RoutingState.NORMAL;
      this._setConnectionState(ConnectionState.CONNECTED);
      this._socket.write(PresenceStanza(
          from: jid.innerText(),
          show: PresenceShow.CHAT
        ).toXml());
    }
  }
  
  Future<void> _handleStreamNegotiation(XMLNode nonza) async {
    if (nonza.tag != "stream:stream") {
      // Probably a stream error
      this._eventStreamController.add(StreamErrorEvent(
          // TODO:
          error: nonza.tag
      ));
      
      return;
    }

    final streamFeatures = nonza.firstTag("stream:features");
    if (streamFeatures == null) {
      print("ERROR: No stream features in stream");
      this._setConnectionState(ConnectionState.ERROR);
      return;
    }
    
    if (streamFeatures.children.length == 0) {
      this._setConnectionState(ConnectionState.CONNECTED);
      // TODO: Bind resource
      print("bind resource");
      return;
    } else {
      final saslMechanisms = streamFeatures.firstTag("mechanisms");
      if (saslMechanisms == null) {
        // Authenticated negotiation
        print("Auth negotiation");

        streamFeatures.children.forEach((element) {
            final required = element.firstTag("required");
            final suffix = required == null ? "false" : "true";
            final tag = element.tag;
            
            print(tag + ": " + suffix);
        });
        
        final required = streamFeatures.children.firstWhere((element) {
            return element.firstTag("required") != null;
        });

        switch (required.tag) {
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

        final bool supportsScramSha1 = saslMechanisms.findTags("mechanism").any(
          (node) => node.innerText() == "SCRAM-SHA-1"
        );

        if (!supportsScramSha1) {
          print("ERROR: Server does not support SCRAM-SHA-1");
          this._setConnectionState(ConnectionState.ERROR);
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

  void _handleStanza(XMLNode stanza) {
    // TODO: Improve stanza handling
    print("Got " + stanza.tag);

    final id = stanza.attributes["id"];
    if (id != null && this._awaitingResponse.containsKey(id)) {
      this._awaitingResponse[id]!.complete(stanza);
      this._awaitingResponse.remove(id);
    }
    
    switch (stanza.tag) {
      case "message": {
        // TODO

        final body = stanza.firstTag("body");
        if (body != null) {
          final from = stanza.attributes["from"]!;
          final sid = stanza.attributes["id"]!;

          this._eventStreamController.add(
            MessageEvent(
              body: body.innerText(),
              fromJid: from,
              sid: sid
            )
          );
        } else {
          // TODO: This will crash if there are no markers
          final chatMarker = stanza.children.firstWhere(
            (element) => chatMarkerFromTag(element.tag) != ChatMarkerType.UNKNOWN
          );

          this._eventStreamController.add(
            ChatMarkerEvent(
              type: chatMarkerFromTag(chatMarker.tag),
              sid: stanza.attributes["id"]!
            )
          );
        } 
      }
      break;
    }
  }

  void handleXmlStream(XMLNode node) async {
    print("(xml) <== " + node.toXml());

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
      .transform(StreamTransformer<String, XMLNode>.fromHandlers(handleData: this._filterOutStreamBegin))
      .forEach(this.handleXmlStream);

    this._setConnectionState(ConnectionState.CONNECTING);
    this._sendStreamHeader();
  }
}
