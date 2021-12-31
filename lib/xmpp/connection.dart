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
import "package:moxxyv2/xmpp/sasl/authenticators.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/iq.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";
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
  late final Stream<String> _socketStream;
  late final StreamController<XmppEvent> _eventStreamController;
  StreamManager? streamManager;
  final Map<String, Completer<XMLNode>> _awaitingResponse = Map();
  
  final List<StanzaHandler> _stanzaHandlers = [
    StanzaHandler(tagName: "query", xmlns: DISCO_INFO_XMLNS, callback: answerDiscoInfoQuery),
    StanzaHandler(tagName: "query", xmlns: DISCO_ITEMS_XMLNS, callback: answerDiscoItemsQuery),
    StanzaHandler(callback: handleMessageStanza)
  ];

  // Stream properties
  final List<String> _streamFeatures = List.empty(growable: true); // Stream feature XMLNS
  // final List<String> _serverFeatures = List.empty(growable: true);
  late RoutingState _routingState;
  late String _resource;

  // Negotiators
  late final AuthenticationNegotiator _authenticator;

  XmppConnection({ required this.settings, SocketWrapper? socket }) {
    this._connectionState = ConnectionState.NOT_CONNECTED;
    this._routingState = RoutingState.UNAUTHENTICATED;

    // NOTE: For testing 
    if (socket != null) {
      this._socket = socket;
    } else {
      this._socket = SocketWrapper();
    }

    this._eventStreamController = StreamController();
    this._resource = "";
  }
  
  // Returns true if the stream supports the XMLNS @feature.
  bool streamFeatureSupported(String feature) {
    return this._streamFeatures.indexOf(feature) != -1;
  }

  // Internal function for support of XEP-0198
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
    // Add extra data in case it was not set
    if (addId && (stanza.id == null || stanza.id == "")) {
      stanza = stanza.copyWith(id: randomAlphaNumeric(20));
    }
    if (addFrom && (stanza.from == null || stanza.from == "")) {
      stanza = stanza.copyWith(from: this.settings.jid.withResource(this._resource).toString());
    }

    final stanzaString = stanza.toXml();

    // Tell the SM manager that we're about to send a stanza
    if (this.streamManager != null) {
      this.streamManager!.clientStanzaSent(stanzaString);
    }
    
    this._awaitingResponse[stanza.id!] = Completer();
    this._socket.write(stanzaString);

    // Try to ack every stanza
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

  // Returns true if we should proceed and false if not.
  bool _handleResourceBindingResult(XMLNode stanza) {
    if (stanza.tag != "iq" || stanza.attributes["type"] != "result") {
      print("ERROR: Resource binding failed!");
      this._routingState = RoutingState.ERROR;
      return false;
    }

    // Success
    final bind = stanza.firstTag("bind")!;
    final jid = bind.firstTag("jid")!;
    // TODO: Use our FullJID class
    this._resource = jid.innerText().split("/")[1];
    return true;
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
  }

  void handleSaslResult(AuthenticationResult result) {
    switch (result) {
      case AuthenticationResult.SUCCESS: this._routingState = RoutingState.CHECK_STREAM_MANAGEMENT;
      break;
      case AuthenticationResult.FAILURE: this._routingState = RoutingState.ERROR;
      break;
      case AuthenticationResult.NOT_DONE:
      break;
    }
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
      case RoutingState.UNAUTHENTICATED: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          print("ERROR: Expected stream header");
          this._routingState = RoutingState.ERROR;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;
        final mechanismNodes = streamFeatures.firstTag("mechanisms")!;
        final mechanisms = mechanismNodes.children.map((node) => node.innerText()).toList();
        final authenticator = getAuthenticator(
          mechanisms,
          this.settings,
          this.sendRawXML,
        );

        if (authenticator == null) {
          this._routingState = RoutingState.ERROR;
          return;
        } else {
          this._authenticator = authenticator;
        }

        this._routingState = RoutingState.PERFORM_SASL_AUTH;
        final result = await this._authenticator.next(null);
        //this._handleSaslResult();
        if (result == AuthenticationResult.SUCCESS) {
          this._routingState = RoutingState.CHECK_STREAM_MANAGEMENT;
          this._sendStreamHeader();
        }
      }
      break;
      case RoutingState.PERFORM_SASL_AUTH: {
        final result = await this._authenticator.next(node);
        //this._handleSaslResult();
        if (result == AuthenticationResult.SUCCESS) {
          this._routingState = RoutingState.CHECK_STREAM_MANAGEMENT;
          this._sendStreamHeader();
        }
      }
      break;
      case RoutingState.CHECK_STREAM_MANAGEMENT: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          print("ERROR: Expected stream header");
          this._routingState = RoutingState.ERROR;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;
        // TODO: Handle required features?
        streamFeatures.children.forEach((node) => this._streamFeatures.add(node.attributes["xmlns"]));

        if (this.streamFeatureSupported(SM_XMLNS)) {
          // Try to work with SM first
          if (/*this.settings.streamResumptionId != null*/ false) {
            // Try to resume the last stream
            // TODO
          } else {
            // Try to enable SM
            this._routingState = RoutingState.BIND_RESOURCE_PRE_SM;
            this._performResourceBinding();
          }
        } else {
          this._routingState = RoutingState.BIND_RESOURCE;
          this._performResourceBinding();
        }
      }
      break;
      case RoutingState.BIND_RESOURCE_PRE_SM: {
        final proceed = this._handleResourceBindingResult(node);
        if (proceed) {
          this._routingState = RoutingState.ENABLE_SM;
          this.sendRawXML(StreamManagementEnableNonza());
        }
      }
      break;
      case RoutingState.ENABLE_SM: {
        if (node.tag == "failed") {
          // Not critical
          print("Failed to enable SM: " + node.tag);
          this._routingState = RoutingState.HANDLE_STANZAS;
          this._sendInitialPresence();
        } else if (node.tag == "enabled") {
          print("SM enabled!");

          // TODO: Assuming that having the ID implies that we can resume
          final id = node.attributes["id"];
          if (id != null) {
            print("Stream resumption possible!");
            this.sendEvent(StreamResumptionEvent(id: id));
          }

          this.streamManager = StreamManager(connection: this, streamResumptionId: id);
          this._routingState = RoutingState.HANDLE_STANZAS;
          this._sendInitialPresence();
        }
      }
      break;
      case RoutingState.HANDLE_STANZAS: {
        this._handleStanza(node);
      }
      break;
    }
  }

  void sendEvent(XmppEvent event) {
    this._eventStreamController.add(event);
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
