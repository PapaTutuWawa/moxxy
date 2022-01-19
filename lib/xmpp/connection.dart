import "dart:io";
import "dart:convert";
import "dart:async";
import "dart:math";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/xmpp/socket.dart";
import "package:moxxyv2/xmpp/buffer.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/plain.dart";
import "package:moxxyv2/xmpp/sasl/scram.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/sasl/authenticators.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/nonzas/csi.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/iq.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";
import "package:moxxyv2/xmpp/xeps/0030.dart";
import "package:moxxyv2/xmpp/xeps/0115.dart";

import "package:xml/xml.dart";
import "package:xml/xml_events.dart";
import "package:uuid/uuid.dart";

enum ConnectionState {
  NOT_CONNECTED,
  CONNECTING,
  CONNECTED,
  ERROR
}

class ConnectionStateChangedEvent extends XmppEvent {
  final ConnectionState state;

  ConnectionStateChangedEvent({ required this.state });
}

class StreamErrorEvent extends XmppEvent {
  final String error;

  StreamErrorEvent({ required this.error });
}

class AuthenticationFailedEvent extends XmppEvent {
  final String saslError;

  AuthenticationFailedEvent({ required this.saslError });
}

class XmppConnection {
  late ConnectionSettings _connectionSettings;
  late final BaseSocketWrapper _socket;
  late ConnectionState _connectionState;
  late final Stream<String> _socketStream;
  late final StreamController<XmppEvent> _eventStreamController;
  final Map<String, Completer<XMLNode>> _awaitingResponse = Map();
  final Map<String, XmppManagerBase> _xmppManagers = Map();
  
  // Stream properties
  //
  // Stream feature XMLNS
  List<String> _streamFeatures = List.empty(growable: true);
  // TODO
  // final List<String> _serverFeatures = List.empty(growable: true);
  late RoutingState _routingState;
  late String _resource;
  late XmlStreamBuffer _streamBuffer;
  Timer? _connectionPingTimer;
  late int _currentBackoffAttempt;
  Timer? _backoffTimer;
  late final Uuid _uuid;

  // Negotiators
  late AuthenticationNegotiator _authenticator;

  // Misc
  late final void Function(String) _log;
  
  XmppConnection({ BaseSocketWrapper? socket, Function(String) log = print }) {
    this._connectionState = ConnectionState.NOT_CONNECTED;
    this._routingState = RoutingState.UNAUTHENTICATED;

    // NOTE: For testing 
    if (socket != null) {
      this._socket = socket;
    } else {
      this._socket = TCPSocketWrapper(log: log);
    }

    this._eventStreamController = StreamController();
    this._resource = "";
    this._streamBuffer = XmlStreamBuffer();
    this._currentBackoffAttempt = 0;
    this._connectionState = ConnectionState.NOT_CONNECTED;
    this._log = log;

    this._socketStream = this._socket.getDataStream();
    // TODO: Handle on done
    this._socketStream.listen(this._incomingMiddleware);
    // TODO: Handle the stream buffer in the socket
    this._socketStream.transform(this._streamBuffer).forEach(this.handleXmlStream);
    this._socket.getErrorStream().listen(this._handleError);

    this._uuid = Uuid();
  }

  /// Registers an [XmppManagerBase] subclass as a manager on this connection
  void registerManager(XmppManagerBase manager) {
    this._log("Registering ${manager.getId()}");
    manager.register(XmppManagerAttributes(
        log: (message) {
          this._log("[${manager.getId()}] $message");
        },
        sendStanza: this.sendStanza,
        sendNonza: this.sendRawXML,
        sendRawXml: this._socket.write,
        sendEvent: this.sendEvent,
        getConnectionSettings: () => this._connectionSettings,
        getManager: getManagerById
    ));

    this._xmppManagers[manager.getId()] = manager;
  }

  /// Returns the Manager with id [id] or null if such a manager is not registered
  T? getManagerById<T>(String id) {
    final manager = _xmppManagers[id];
    if (manager != null) {
      return manager as T;
    }

    return null;
  }
  
  void setConnectionSettings(ConnectionSettings settings) {
    this._connectionSettings = settings;
  }

  ConnectionSettings getConnectionSettings() => this._connectionSettings;
  
  void _handleError(Object error) {
    this._log("ERROR: " + error.toString());

    // TODO: This may be to harsh for every error
    this._setConnectionState(ConnectionState.NOT_CONNECTED);
    this._socket.close();

    if (this._currentBackoffAttempt == 0) {
      final minutes = pow(2, this._currentBackoffAttempt).toInt();
      this._currentBackoffAttempt++;
      this._backoffTimer = Timer(Duration(minutes: minutes), () {
          this.connect();
      });
    }
  }

  /// Returns true if the stream supports the XMLNS @feature.
  bool streamFeatureSupported(String feature) {
    return this._streamFeatures.indexOf(feature) != -1;
  }

  /// Sends an [XMLNode] without any further processing to the server.
  void sendRawXML(XMLNode node) {
    this._socket.write(node.toXml());
  }

  /// Send a message to [to] with the content [body].
  void sendMessage(String body, String to) async {
    this.sendStanza(Stanza.message(
        to: to,
        type: "normal",
        children: [
          XMLNode(tag: "body", text: body)
        ]
    ));
  }

  /// Sends a [stanza] to the server. If stream management is enabled, then keeping track
  /// of the stanza is taken care of. Returns a Future that resolves when we receive a
  /// response to the stanza.
  ///
  /// If addFrom is true, then a "from" attribute will be added to the stanza if
  /// [stanza] has none.
  /// If addId is true, then an "id" attribute will be added to the stanza if [stanza] has
  /// none.
  Future<XMLNode> sendStanza(Stanza stanza, { bool addFrom = true, bool addId = true }) {
    // Add extra data in case it was not set
    if (addId && (stanza.id == null || stanza.id == "")) {
      stanza = stanza.copyWith(id: this._uuid.v4());
    }
    if (addFrom && (stanza.from == null || stanza.from == "")) {
      stanza = stanza.copyWith(from: this._connectionSettings.jid.withResource(this._resource).toString());
    }

    final stanzaString = stanza.toXml();
    
    this._awaitingResponse[stanza.id!] = Completer();

    // TODO: Restrict the CONNECTING condition s.t. routingState must be one of
    // This uses the StreamManager to behave like a send queue
    if (this._connectionState == ConnectionState.CONNECTED || this._connectionState == ConnectionState.CONNECTING) {
      this._socket.write(stanzaString);

      // Try to ack every stanza
      // NOTE: Here we have send an Ack request nonza. This is now done by StreamManagementManager when receiving the StanzaSentEvent
    }

    // Tell the SM manager that we're about to send a stanza
    this.sendEvent(StanzaSentEvent(stanza: stanza));
    
    return this._awaitingResponse[stanza.id!]!.future;
  }

  /// Sets the connection state to [state] and triggers an event of type
  /// [ConnectionStateChangedEvent].
  void _setConnectionState(ConnectionState state) {
    this._connectionState = state;
    this._eventStreamController.add(ConnectionStateChangedEvent(state: state));

    if (state == ConnectionState.CONNECTED) {
      this._connectionPingTimer = Timer.periodic(Duration(minutes: 5), this._pingConnectionOpen);
    } else {
      if (this._connectionPingTimer != null) {
        this._connectionPingTimer!.cancel();
        this._connectionPingTimer = null;
      }
    }
  }

  /// Returns the connection's events as a stream.
  Stream<XmppEvent> asBroadcastStream() {
    return this._eventStreamController.stream.asBroadcastStream();
  }
  
  // Just for logging
  void _incomingMiddleware(String data) {
    this._log("<== " + data);
  }

  /// Perform a resource bind with a server-generated resource.
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

  /// Handles the result to the resource binding request and returns true if we should
  /// proceed and false if not.
  bool _handleResourceBindingResult(XMLNode stanza) {
    if (stanza.tag != "iq" || stanza.attributes["type"] != "result") {
      this._log("ERROR: Resource binding failed!");
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

  /// Sends the initial presence to enable receiving messages.
  Future<void> _sendInitialPresence() async {
    // TODO: Cache for the next presence broadcast
    final capHash = await calculateCapabilityHash(
      DiscoInfo(
        features: DISCO_FEATURES,
        identities: [
          Identity(
            category: "client",
            type: "phone",
            name: "Moxxy"
          )
        ]
      )
    );
    this.sendStanza(Stanza.presence(
        from: this._connectionSettings.jid.withResource(this._resource).toString(),
        children: [
          XMLNode(
            tag: "show",
            text: "chat"
          ),
          XMLNode.xmlns(
            tag: "c",
            xmlns: CAPS_XMLNS,
            attributes: {
              "hash": "sha-1",
              "node": "http://moxxy.im",
              "ver": capHash
            }
          )
        ]
    ));
  }

  /// Timer callback to prevent the connection from timing out.
  void _pingConnectionOpen(Timer timer) {
    // Follow the recommendation of XEP-0198 and just request an ack. If SM is not enabled,
    // send a whitespace ping
    if (this._connectionState == ConnectionState.CONNECTED) {
      final smManager = this._xmppManagers[SM_MANAGER];
      // TODO: Maybe just trigger an event
      this.sendEvent(SendPingEvent());
    }
  }

  /// Called whenever we receive a stanza after resource binding or stream resumption.
  void _handleStanza(XMLNode stanzaRaw) {
    // TODO: Improve stanza handling
    // Ignore nonzas
    if (["message", "iq", "presence"].indexOf(stanzaRaw.tag) == -1) {
      bool nonzaHandled = false;
      this._xmppManagers.values.forEach((manager) {
          // TODO: Maybe abort after the first match
          final handlers = manager.getNonzaHandlers();
          handlers.forEach((handler) {
              if (handler.matches(stanzaRaw)) {
                handler.callback(stanzaRaw);
                nonzaHandled = true;
              }
          });
      });

      if (!nonzaHandled) {
        this._log("Unhandled nonza received: " + stanzaRaw.toXml());
      }
      return;
    }
    
    final stanza = Stanza.fromXMLNode(stanzaRaw);
    final id = stanza.attributes["id"];
    if (id != null && this._awaitingResponse.containsKey(id)) {
      this._awaitingResponse[id]!.complete(stanza);
      this._awaitingResponse.remove(id);
      // TODO: Call it a day here?
      return;
    }

    bool handled = false;
    this._xmppManagers.values.forEach((manager) {
        // TODO: Maybe abort after the first match
        final handlers = manager.getStanzaHandlers();
        handlers.forEach((handler) {
            if (handler.matches(stanza)) {
              final result = handler.callback(stanza);
              handled = true;
            }
        });
    });

    if (!handled) {
      handleUnhandledStanza(this, stanza);
    }
  }

  /// Called whenever we receive data that has been parsed as XML.
  void handleXmlStream(XMLNode node) async {
    this._log("(xml) <== " + node.toXml());

    // TODO: Handle RoutingState.BIND_RESOURCE
    switch (this._routingState) {
      case RoutingState.UNAUTHENTICATED: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          this._log("ERROR: Expected stream header");
          this._routingState = RoutingState.ERROR;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;
        final mechanismNodes = streamFeatures.firstTag("mechanisms")!;
        final mechanisms = mechanismNodes.children.map((node) => node.innerText()).toList();
        final authenticator = getAuthenticator(
          mechanisms,
          this._connectionSettings,
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
        if (result.getState() == AuthenticationResult.SUCCESS) {
          this._routingState = RoutingState.CHECK_STREAM_MANAGEMENT;
          this._sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.FAILURE) {
          this._log("SASL failed");
          this.sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          this._setConnectionState(ConnectionState.ERROR);
          this._routingState = RoutingState.ERROR;
        }
      }
      break;
      case RoutingState.PERFORM_SASL_AUTH: {
        final result = await this._authenticator.next(node);
        //this._handleSaslResult();
        if (result.getState() == AuthenticationResult.SUCCESS) {
          this._routingState = RoutingState.CHECK_STREAM_MANAGEMENT;
          this._sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.FAILURE) {
          this._log("SASL failed");
          this.sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          this._setConnectionState(ConnectionState.ERROR);
          this._routingState = RoutingState.ERROR;
        }
      }
      break;
      case RoutingState.CHECK_STREAM_MANAGEMENT: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          this._log("ERROR: Expected stream header");
          this._routingState = RoutingState.ERROR;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;
        // TODO: Handle required features?
        // NOTE: In case of reconnecting
        this._streamFeatures.clear();
        streamFeatures.children.forEach((node) => this._streamFeatures.add(node.attributes["xmlns"]));

        if (this.streamFeatureSupported(SM_XMLNS)) {
          // Try to work with SM first
          if (this._connectionSettings.streamResumptionSettings.id != null) {
            // Try to resume the last stream
            this._routingState = RoutingState.PERFORM_STREAM_RESUMPTION;
            this.sendRawXML(StreamManagementResumeNonza(this._connectionSettings.streamResumptionSettings.id!, this._connectionSettings.streamResumptionSettings.lasth!));
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
      case RoutingState.PERFORM_STREAM_RESUMPTION: {
        // TODO: Synchronize the h values
        if (node.tag == "resumed") {
          this._log("Stream Resumption successful!");
          this.sendEvent(StreamManagementResumptionSuccessfulEvent());
          this._resource = this._connectionSettings.streamResumptionSettings.resource!;
          this._routingState = RoutingState.HANDLE_STANZAS;
          this._setConnectionState(ConnectionState.CONNECTED);

          final h = int.parse(node.attributes["h"]!);
          this.sendEvent(StreamResumedEvent(h: h));
          this._sendInitialPresence();
        } else if (node.tag == "failed") {
          this._log("Stream resumption failed. Proceeding with new stream...");
          this._routingState = RoutingState.BIND_RESOURCE_PRE_SM;
          this._performResourceBinding();
        }
      }
      break;
      case RoutingState.ENABLE_SM: {
        if (node.tag == "failed") {
          // Not critical
          this._log("Failed to enable SM: " + node.tag);
          this._routingState = RoutingState.HANDLE_STANZAS;
          this._sendInitialPresence();
        } else if (node.tag == "enabled") {
          this._log("SM enabled!");

          final id = node.attributes["id"];
          if (id != null && [ "true", "1" ].indexOf(node.attributes["resume"]) != -1) {
            this._log("Stream resumption possible!");
            this.sendEvent(StreamManagementEnabledEvent(id: id, resource: this._resource));
          }

          this._routingState = RoutingState.HANDLE_STANZAS;
          this._sendInitialPresence();
          this._setConnectionState(ConnectionState.CONNECTED);
        }
      }
      break;
      case RoutingState.HANDLE_STANZAS: {
        this._handleStanza(node);
      }
      break;
    }
  }

  /// Sets the CSI state (true: <active />, false: <inactive />) if the stream supports
  /// CSI.
  // TODO: Remember the CSI state in case we resume a stream
  void sendCSIState(bool state) {
    // TODO: Maybe cache this result
    if (this._streamFeatures.indexOf(CSI_XMLNS) == -1) {
      return;
    }
    
    this._socket.write(
      (state ? CSIActiveNonza() : CSIInactiveNonza()).toXml()
    );
  }
  
  /// Sends an event to the connection's event stream.
  void sendEvent(XmppEvent event) {
    this._xmppManagers.values.forEach((manager) => manager.onXmppEvent(event));

    this._eventStreamController.add(event);
  }

  /// Sends a stream header to the socket
  void _sendStreamHeader() {
    this._socket.write(
      XMLNode(
        tag: "xml",
        attributes: {
          "version": "1.0"
        },
        closeTag: false,
        isDeclaration: true,
        children: [
          StreamHeaderNonza(this._connectionSettings.jid.domain)
        ]
      ).toXml()
    );
  }

  /// To be called when we lost network connection
  Future<void> onNetworkConnectionLost() async {
    this._socket.close();
    this._setConnectionState(ConnectionState.NOT_CONNECTED);
  }

  /// To be called when we lost network connection
  Future<void> onNetworkConnectionRegained() async {
    if (this._connectionState == ConnectionState.NOT_CONNECTED) {
      this.connect();
    }
  }
  
  Future<void> connect() async {
    String hostname = this._connectionSettings.jid.domain;
    int port = 5222;

    if (this._backoffTimer != null) {
      this._backoffTimer!.cancel();
      this._backoffTimer = null;
    }
    
    if (this._connectionSettings.useDirectTLS) {
      final query = await perform0368Lookup(this._connectionSettings.jid.domain);

      if (query != null) {
        hostname = query.hostname;
        port = query.port;

        this._log("Did XEP-0368 lookup. Using ${hostname}:${port.toString()} now.");
      }
    }

    this._log("Connecting to $hostname:$port");
    try {
      await this._socket.connect(hostname, port);
    } catch (ex) {
      this._log("Exception while connecting: " + ex.toString());
      this._handleError(ex);
      return;
    }

    this._currentBackoffAttempt = 0; 
    this._setConnectionState(ConnectionState.CONNECTING);
    this._routingState = RoutingState.UNAUTHENTICATED;
    this._sendStreamHeader();
  }
}
