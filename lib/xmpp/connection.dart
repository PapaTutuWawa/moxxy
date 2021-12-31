import "dart:io";
import "dart:convert";
import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/sasl/scramsha1.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stanzas/handlers.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/negotiators/stream.dart";
import "package:moxxyv2/xmpp/negotiators/sm.dart";
import "package:moxxyv2/xmpp/negotiators/resource.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/iq.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";
import "package:moxxyv2/xmpp/xeps/0198.dart";
import "package:moxxyv2/xmpp/xeps/0030.dart";

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
  String _resource = "";
  late final StreamController<XmppEvent> _eventStreamController;
  StreamManager? streamManager;
  final Map<String, Completer<XMLNode>> _awaitingResponse = Map();
  final List<StanzaHandler> _stanzaHandlers = [
    StanzaHandler(tagName: "query", xmlns: DISCO_INFO_XMLNS, callback: answerDiscoInfoQuery),
    StanzaHandler(tagName: "query", xmlns: DISCO_ITEMS_XMLNS, callback: answerDiscoItemsQuery)
  ];
  final Map<String, bool> _streamFeatures = Map(); // Stream feature XMLNS -> required

  // Negotiators
  late final StreamManagementNegotiator _smNegotiator;
  late final StreamFeatureNegotiator _sfNegotiator;
  late final AuthenticationNegotiator authNegotiator;
  late final ResourceBindingNegotiator _rbNegotiator;

  // NOTE: For mocking
  XmppConnection({ required this.settings, SocketWrapper? socket }) {
    this._connectionState = ConnectionState.NOT_CONNECTED;
    this._routingState = RoutingState.NEGOTIATOR;
    if (socket != null) {
      this._socket = socket;
    } else {
      this._socket = SocketWrapper();
    }

    this._smNegotiator = StreamManagementNegotiator(connection: this);
    this._sfNegotiator = StreamFeatureNegotiator(connection: this);
    this._rbNegotiator = ResourceBindingNegotiator(connection: this);
    
    this._eventStreamController = StreamController();
    this._resource = "";
  }
  
  // Returns true if the stream supports the XMLNS @feature.
  bool streamFeatureSupported(String feature) {
    return this._streamFeatures.containsKey(feature);
  }
  
  void smResend(String stanza) {
    assert(this.streamManager != null);
    
    this._socket.write(stanza);
    // NOTE: This function must only be called from within the StreamManager, so it MUST
    //       be non-null
    this.streamManager!.clientStanzaSent(stanza);
  }
  
  void sendRawXML(XMLNode node) {
    this._socket.write(node.toXml());
  }
  
  Future<XMLNode> sendStanza(Stanza stanza, { bool addFrom = true, bool addId = true }) {
    if (addId && (stanza.id == null || stanza.id == "")) {
      stanza = stanza.copyWith(id: randomAlphaNumeric(20));
    }
    if (addFrom && (stanza.from == null || stanza.from == "")) {
      stanza = stanza.copyWith(from: this.settings.jid.withResource(this._resource).toString());
    }

    final stanzaString = stanza.toXml();
    
    if (this.streamManager != null) {
      this.streamManager!.clientStanzaSent(stanzaString);
    }
    
    this._awaitingResponse[stanza.id!] = Completer();
    this._socket.write(stanzaString);
    if (this.streamManager != null) {
      this.sendRawXML(StreamManagementRequestNonza());
    }
    return this._awaitingResponse[stanza.id!]!.future;
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

  // Perform a resource bind with a server-generated resource
  void _performResourceBinding() {
    this._routingState = RoutingState.RESOURCE_BIND;
    this.sendStanza(Stanza.iq(
        type: "set",
        children: [
          XMLNode(
            tag: "bind",
            attributes: {
              "xmlns": BIND_XMLNS
            }
          )
        ]
      ),
      addFrom: false
    );
  }

  void _sendInitialPresence() {
     this.sendStanza(Stanza.presence(
          from: this.settings.jid.withResource(this._resource).toString(),
          children: [
            XMLNode(
              tag: "show",
              text: "chat"
            )
          ]
      ));
  }
  
  void setRoutingState(RoutingState state) {
    final oldState = this._routingState;
    final hasChanged = state != this._routingState;
    this._routingState = state;

    if (hasChanged) {
      switch (state) {
        case RoutingState.NORMAL: {
          this._sendInitialPresence();
          this._setConnectionState(ConnectionState.CONNECTED);
        }
        break;
        case RoutingState.RESOURCE_BIND: {
          if (oldState == RoutingState.STREAM_MANAGEMENT) {
            this._rbNegotiator.setAttemptSMEnable(true);
          }

          this._performResourceBinding();
        }
        break;
        case RoutingState.AUTHENTICATOR: {
          this.authNegotiator.next(null);
        }
        break;
        case RoutingState.STREAM_MANAGEMENT: {
          if (oldState == RoutingState.RESOURCE_BIND) {
            this.sendRawXML(StreamManagementEnableNonza());
          } else {
            this._smNegotiator.next(null);
          }
        }
        break;
      }
    }
  }

  void _handleStanza(XMLNode stanzaRaw) {
    // TODO: Improve stanza handling
    // Ignore nonzas
    if (["message", "iq", "presence"].indexOf(stanzaRaw.tag) == -1) {
      print("Got nonza " + stanzaRaw.tag + " in stanza handler. Ignoring");
      return;
    }

    if (stanzaRaw.tag == "presence") return;
    
    final stanza = Stanza.fromXMLNode(stanzaRaw);
    final id = stanza.attributes["id"];
    if (id != null && this._awaitingResponse.containsKey(id)) {
      this._awaitingResponse[id]!.complete(stanza);
      this._awaitingResponse.remove(id);
      // TODO: Call it a day here?
      return;
    }

    for (int i = 0; i < this._stanzaHandlers.length; i++) {
      if (this._stanzaHandlers[i].matches(stanza)) {
        if (this._stanzaHandlers[i].callback(this, stanza)) return;
      }
    }
    handleUnhandledStanza(this, stanza);

    /*
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
    */
  }

  void handleXmlStream(XMLNode node) async {
    print("(xml) <== " + node.toXml());

    if (this.streamManager != null) {
      if (node.tag == "r") {
        this.streamManager!.handleAckRequest();
      } else if (node.tag == "a") {
        this.streamManager!.handleAckResponse(int.parse(node.attributes["h"]!));
      } else {
        this.streamManager!.serverStanzaReceived();
      }
    }
    
    switch (this._routingState) {
      case RoutingState.NEGOTIATOR: {
        this.setRoutingState(await this._sfNegotiator.next(node));
      }
      break;
      case RoutingState.AUTHENTICATOR: {
        this.setRoutingState(await this.authNegotiator.next(node));
      }
      break;
      case RoutingState.STREAM_MANAGEMENT: {
        this.setRoutingState(await this._smNegotiator.next(node));
      }
      break;
      case RoutingState.RESOURCE_BIND: {
        this.setRoutingState(await this._rbNegotiator.next(node));
      }
      break;
      case RoutingState.NORMAL: {
        this._handleStanza(node);
      }
      break;
    }
  }

  void sendEvent(XmppEvent event) {
    this._eventStreamController.add(event);
  }

  void setResource(String resource) {
    this._resource = resource;
  }
  
  void setStreamFeature(String feature, bool _required) {
    this._streamFeatures[feature] = _required;
  }
  
  void sendStreamHeader() {
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
    this.sendStreamHeader();
  }
}
