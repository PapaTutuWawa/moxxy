import "dart:async";
import "dart:math";

import "package:moxxyv2/xmpp/socket.dart";
import "package:moxxyv2/xmpp/buffer.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/sasl/authenticators.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/iq.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198.dart";
import "package:moxxyv2/xmpp/xeps/xep_0368.dart";

import "package:uuid/uuid.dart";

enum ConnectionState {
  notConnected,
  connecting,
  connected,
  error
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
  final Map<String, Completer<XMLNode>> _awaitingResponse = {};
  final Map<String, XmppManagerBase> _xmppManagers = {};
  
  // Stream properties
  //
  // Stream feature XMLNS
  final List<String> _streamFeatures = List.empty(growable: true);
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
    _connectionState = ConnectionState.notConnected;
    _routingState = RoutingState.unauthenticated;

    // NOTE: For testing 
    if (socket != null) {
      _socket = socket;
    } else {
      _socket = TCPSocketWrapper(log: log);
    }

    _eventStreamController = StreamController();
    _resource = "";
    _streamBuffer = XmlStreamBuffer();
    _currentBackoffAttempt = 0;
    _connectionState = ConnectionState.notConnected;
    _log = log;

    _socketStream = _socket.getDataStream();
    // TODO: Handle on done
    _socketStream.listen(_incomingMiddleware);
    // TODO: Handle the stream buffer in the socket
    _socketStream.transform(_streamBuffer).forEach(handleXmlStream);
    _socket.getErrorStream().listen(_handleError);

    _uuid = const Uuid();
  }

  /// Registers an [XmppManagerBase] subclass as a manager on this connection
  void registerManager(XmppManagerBase manager) {
    _log("Registering ${manager.getId()}");
    manager.register(XmppManagerAttributes(
        log: (message) {
          _log("[${manager.getId()}] $message");
        },
        sendStanza: sendStanza,
        sendNonza: sendRawXML,
        sendRawXml: _socket.write,
        sendEvent: _sendEvent,
        getConnectionSettings: () => _connectionSettings,
        getManagerById: getManagerById,
        isStreamFeatureSupported: isStreamFeatureSupported,
        getFullJID: () => _connectionSettings.jid.withResource(_resource)
    ));

    _xmppManagers[manager.getId()] = manager;
  }

  /// Returns the Manager with id [id] or null if such a manager is not registered.
  T? getManagerById<T>(String id) {
    final manager = _xmppManagers[id];
    if (manager != null) {
      return manager as T;
    }

    return null;
  }

  /// A [PresenceManager] is required so have a wrapper for getting it.
  /// Returns the registered [PresenceManager].
  PresenceManager getPresenceManager() {
    assert(_xmppManagers.containsKey(presenceManager));

    return getManagerById(presenceManager)!;
  }
  
  /// Set the connection settings of this connection.
  void setConnectionSettings(ConnectionSettings settings) {
    _connectionSettings = settings;
  }

  /// Returns the connection settings of this connection.
  ConnectionSettings getConnectionSettings() {
    return _connectionSettings;
  }
  
  void _handleError(Object error) {
    _log("ERROR: " + error.toString());

    // TODO: This may be too harsh for every error
    _setConnectionState(ConnectionState.notConnected);
    _socket.close();

    if (_currentBackoffAttempt == 0) {
      // TODO: This may to too long
      final minutes = pow(2, _currentBackoffAttempt).toInt();
      _currentBackoffAttempt++;
      _backoffTimer = Timer(Duration(minutes: minutes), () {
          connect();
      });
    }
  }

  /// NOTE: For debugging purposes only
  /// Returns the internal state of the state machine
  RoutingState getRoutingState() {
    return _routingState;
  }
  
  /// Returns true if the stream supports the XMLNS @feature.
  bool isStreamFeatureSupported(String feature) {
    return _streamFeatures.contains(feature);
  }

  /// Sends an [XMLNode] without any further processing to the server.
  void sendRawXML(XMLNode node) {
    _socket.write(node.toXml());
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
      stanza = stanza.copyWith(id: _uuid.v4());
    }
    if (addFrom && (stanza.from == null || stanza.from == "")) {
      stanza = stanza.copyWith(from: _connectionSettings.jid.withResource(_resource).toString());
    }

    final stanzaString = stanza.toXml();
    
    _awaitingResponse[stanza.id!] = Completer();

    // TODO: Restrict the connecteing condition s.t. routingState must be one of
    // This uses the StreamManager to behave like a send queue
    if (_connectionState == ConnectionState.connected || _connectionState == ConnectionState.connecting) {
      _socket.write(stanzaString);

      // Try to ack every stanza
      // NOTE: Here we have send an Ack request nonza. This is now done by StreamManagementManager when receiving the StanzaSentEvent
    }

    // Tell the SM manager that we're about to send a stanza
    _sendEvent(StanzaSentEvent(stanza: stanza));
    
    return _awaitingResponse[stanza.id!]!.future;
  }

  /// Sets the connection state to [state] and triggers an event of type
  /// [ConnectionStateChangedEvent].
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    _eventStreamController.add(ConnectionStateChangedEvent(state: state));

    if (state == ConnectionState.connected) {
      _connectionPingTimer = Timer.periodic(const Duration(minutes: 5), _pingConnectionOpen);
    } else {
      if (_connectionPingTimer != null) {
        _connectionPingTimer!.cancel();
        _connectionPingTimer = null;
      }
    }
  }

  /// Returns the connection's events as a stream.
  Stream<XmppEvent> asBroadcastStream() {
    return _eventStreamController.stream.asBroadcastStream();
  }
  
  // Just for logging
  void _incomingMiddleware(String data) {
    _log("<== " + data);
  }

  /// Perform a resource bind with a server-generated resource.
  void _performResourceBinding() {
    sendStanza(Stanza.iq(
        type: "set",
        children: [
          XMLNode(
            tag: "bind",
            attributes: {
              "xmlns": bindXmlns
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
      _log("ERROR: Resource binding failed!");
      _routingState = RoutingState.error;
      return false;
    }

    // Success
    final bind = stanza.firstTag("bind")!;
    final jid = bind.firstTag("jid")!;
    // TODO: Use our FullJID class
    _resource = jid.innerText().split("/")[1];

    _sendEvent(ResourceBindingSuccessEvent(resource: _resource));

    return true;
  }

  /// Timer callback to prevent the connection from timing out.
  void _pingConnectionOpen(Timer timer) {
    // Follow the recommendation of XEP-0198 and just request an ack. If SM is not enabled,
    // send a whitespace ping
    if (_connectionState == ConnectionState.connected) {
      _sendEvent(SendPingEvent());
    }
  }

  /// Called whenever we receive a stanza after resource binding or stream resumption.
  Future<void> _handleStanza(XMLNode nonza) async {
    // Process nonzas separately
    if (["message", "iq", "presence"].contains(nonza.tag)) {
      bool nonzaHandled = false;
      await Future.forEach(
        _xmppManagers.values,
        (XmppManagerBase manager) async {
          final handled = await manager.runNonzaHandlers(nonza);

          if (!nonzaHandled && handled) nonzaHandled = true;
        }
      );

      if (!nonzaHandled) {
        _log("Unhandled nonza received: " + nonza.toXml());
      }
      return;
    }
    
    final stanza = Stanza.fromXMLNode(nonza);
    final id = stanza.attributes["id"];
    if (id != null && _awaitingResponse.containsKey(id)) {
      _awaitingResponse[id]!.complete(stanza);
      _awaitingResponse.remove(id);
      // TODO: Call it a day here?
      return;
    }

    bool stanzaHandled = false;
    await Future.forEach(
      _xmppManagers.values,
      (XmppManagerBase manager) async {
        final handled = await manager.runStanzaHandlers(stanza);

        if (!stanzaHandled && handled) stanzaHandled = true;
      }
    );

    if (!stanzaHandled) {
      handleUnhandledStanza(this, stanza);
    }
  }

  /// Called whenever we receive data that has been parsed as XML.
  void handleXmlStream(XMLNode node) async {
    _log("(xml) <== " + node.toXml());

    switch (_routingState) {
      case RoutingState.unauthenticated: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          _log("ERROR: Expected stream header");
          _routingState = RoutingState.error;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;
        final mechanismNodes = streamFeatures.firstTag("mechanisms")!;
        final mechanisms = mechanismNodes.children.map((node) => node.innerText()).toList();
        final authenticator = getAuthenticator(
          mechanisms,
          _connectionSettings,
          sendRawXML,
        );

        if (authenticator == null) {
          _routingState = RoutingState.error;
          return;
        } else {
          _authenticator = authenticator;
        }

        _routingState = RoutingState.performSaslAuth;
        final result = await _authenticator.next(null);
        if (result.getState() == AuthenticationResult.success) {
          _routingState = RoutingState.checkStreamManagement;
          _sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.failure) {
          _log("SASL failed");
          _sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          _setConnectionState(ConnectionState.error);
          _routingState = RoutingState.error;
        }
      }
      break;
      case RoutingState.performSaslAuth: {
        final result = await _authenticator.next(node);
        if (result.getState() == AuthenticationResult.success) {
          _routingState = RoutingState.checkStreamManagement;
          _sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.failure) {
          _log("SASL failed");
          _sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          _setConnectionState(ConnectionState.error);
          _routingState = RoutingState.error;
        }
      }
      break;
      case RoutingState.checkStreamManagement: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          _log("ERROR: Expected stream header");
          _routingState = RoutingState.error;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;
        // TODO: Handle required features?
        // NOTE: In case of reconnecting
        _streamFeatures.clear();
        for (var node in streamFeatures.children) {
          _streamFeatures.add(node.attributes["xmlns"]);
        }

        // TODO: Give the stream manager its own getter in this class
        if (isStreamFeatureSupported(smXmlns) && _xmppManagers.containsKey(smManager)) {
          final manager = _xmppManagers[smManager]! as StreamManagementManager;
          await manager.loadStreamResumptionId();
          await manager.loadClientSeq();
          final srid = manager.getStreamResumptionId();
          final h = manager.getClientStanzaSeq();
          
          // Try to work with SM first
          if (srid != null) {
            // Try to resume the last stream
            _routingState = RoutingState.performStreamResumption;
            sendRawXML(StreamManagementResumeNonza(srid, h));
          } else {
            // Try to enable SM
            _routingState = RoutingState.bindResourcePreSM;
            _performResourceBinding();
          }
        } else {
          _routingState = RoutingState.bindResource;
          _performResourceBinding();
        }
      }
      break;
      case RoutingState.bindResource: {
        final proceed = _handleResourceBindingResult(node);
        if (proceed) {
          _routingState = RoutingState.handleStanzas;
          getPresenceManager().sendInitialPresence();
        } else {
          _log("Resource binding failed!");
          _routingState = RoutingState.error;
          _setConnectionState(ConnectionState.error);
        }
      }
      break;
      case RoutingState.bindResourcePreSM: {
        final proceed = _handleResourceBindingResult(node);
        if (proceed) {
          _routingState = RoutingState.enableSM;
          sendRawXML(StreamManagementEnableNonza());
        }
      }
      break;
      case RoutingState.performStreamResumption: {
        if (node.tag == "resumed") {
          _log("Stream Resumption successful!");
          _sendEvent(StreamManagementResumptionSuccessfulEvent());
          // NOTE: _resource is already set if we resume
          assert(_resource != "");
          _routingState = RoutingState.handleStanzas;
          _setConnectionState(ConnectionState.connected);

          final h = int.parse(node.attributes["h"]!);
          _sendEvent(StreamResumedEvent(h: h));
        } else if (node.tag == "failed") {
          _log("Stream resumption failed. Proceeding with new stream...");
          _routingState = RoutingState.bindResourcePreSM;
          _performResourceBinding();
        }
      }
      break;
      case RoutingState.enableSM: {
        if (node.tag == "failed") {
          // Not critical
          _log("Failed to enable SM: " + node.tag);
          _routingState = RoutingState.handleStanzas;
          getPresenceManager().sendInitialPresence();
        } else if (node.tag == "enabled") {
          _log("SM enabled!");

          final id = node.attributes["id"];
          if (id != null && [ "true", "1" ].contains(node.attributes["resume"])) {
            _log("Stream resumption possible!");
            _sendEvent(StreamManagementEnabledEvent(id: id, resource: _resource));
          }

          _routingState = RoutingState.handleStanzas;
          getPresenceManager().sendInitialPresence();
          _setConnectionState(ConnectionState.connected);
        }
      }
      break;
      case RoutingState.handleStanzas: {
        await _handleStanza(node);
      }
      break;
    }
  }
  
  /// Sends an event to the connection's event stream.
  void _sendEvent(XmppEvent event) {
    for (var manager in _xmppManagers.values) {
      manager.onXmppEvent(event);
    }

    _eventStreamController.add(event);
  }

  /// Sends a stream header to the socket.
  void _sendStreamHeader() {
    _socket.write(
      XMLNode(
        tag: "xml",
        attributes: {
          "version": "1.0"
        },
        closeTag: false,
        isDeclaration: true,
        children: [
          StreamHeaderNonza(_connectionSettings.jid.domain)
        ]
      ).toXml()
    );
  }

  /// To be called when we lost network connection
  Future<void> onNetworkConnectionLost() async {
    _socket.close();
    _setConnectionState(ConnectionState.notConnected);
  }

  /// To be called when we lost network connection
  Future<void> onNetworkConnectionRegained() async {
    if (_connectionState == ConnectionState.notConnected) {
      connect();
    }
  }

  /// Start the connection process using the provided connection settings.
  Future<void> connect({ String? lastResource }) async {
    String hostname = _connectionSettings.jid.domain;
    int port = 5222;

    if (lastResource != null) {
      _resource = lastResource;
    }
    
    if (_backoffTimer != null) {
      _backoffTimer!.cancel();
      _backoffTimer = null;
    }
    
    if (_connectionSettings.useDirectTLS) {
      final query = await perform0368Lookup(_connectionSettings.jid.domain);

      if (query != null) {
        hostname = query.hostname;
        port = query.port;

        _log("Did XEP-0368 lookup. Using $hostname:${port.toString()} now.");
      }
    }

    _log("Connecting to $hostname:$port");
    try {
      await _socket.connect(hostname, port);
    } catch (ex) {
      _log("Exception while connecting: " + ex.toString());
      _handleError(ex);
      return;
    }

    _currentBackoffAttempt = 0; 
    _setConnectionState(ConnectionState.connecting);
    _routingState = RoutingState.unauthenticated;
    _sendStreamHeader();
  }
}
