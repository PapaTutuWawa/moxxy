import "dart:async";
import "dart:math";

import "package:moxxyv2/xmpp/socket.dart";
import "package:moxxyv2/xmpp/buffer.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/iq.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/authenticators.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";

import "package:uuid/uuid.dart";
import "package:logging/logging.dart";

enum XmppConnectionState {
  notConnected,
  connecting,
  connected,
  error
}

class StreamHeaderNonza extends XMLNode {
  StreamHeaderNonza(String serverDomain) : super(
      tag: "stream:stream",
      attributes: {
        "xmlns": stanzaXmlns,
        "version": "1.0",
        "xmlns:stream": streamXmlns,
        "to": serverDomain,
        "xml:lang": "en"
      },
      closeTag: false
    );
}

class StartTLSNonza extends XMLNode {
  StartTLSNonza() : super.xmlns(
    tag: "starttls",
    xmlns: startTlsXmlns
  );
}

class XmppConnection {
  late ConnectionSettings _connectionSettings;
  late final BaseSocketWrapper _socket;
  late XmppConnectionState _connectionState;
  late final Stream<String> _socketStream;
  late final StreamController<XmppEvent> _eventStreamController;
  final Map<String, Completer<XMLNode>> _awaitingResponse = {};
  final Map<String, XmppManagerBase> _xmppManagers = {};
  
  // Stream properties
  //
  // Stream feature XMLNS
  final List<String> _streamFeatures = List.empty(growable: true);
  final List<String> _serverFeatures = List.empty(growable: true);
  late RoutingState _routingState;
  late String _resource;
  late XmlStreamBuffer _streamBuffer;
  Timer? _connectionPingTimer;
  late int _currentBackoffAttempt;
  Timer? _backoffTimer;
  late final Uuid _uuid;
  bool _resuming; // For indicating in a [ConnectionStateChangedEvent] that the event occured because we did a reconnection
  final Duration connectionPingDuration;

  // Negotiators
  late AuthenticationNegotiator _authenticator;

  // Misc
  late final Logger _log;

  /// [socket] is for debugging purposes.
  /// [connectionPingDuration] is the duration after which a ping will be sent to keep
  /// the connection open. Defaults to 15 minutes.
  XmppConnection({
      BaseSocketWrapper? socket,
      this.connectionPingDuration = const Duration(minutes: 15)
  }): _resuming = true {
    _connectionState = XmppConnectionState.notConnected;
    _routingState = RoutingState.unauthenticated;

    // NOTE: For testing 
    if (socket != null) {
      _socket = socket;
    } else {
      _socket = TCPSocketWrapper();
    }

    _eventStreamController = StreamController();
    _resource = "";
    _streamBuffer = XmlStreamBuffer();
    _currentBackoffAttempt = 0;
    _connectionState = XmppConnectionState.notConnected;
    _log = Logger("XmppConnection");

    _socketStream = _socket.getDataStream();
    // TODO: Handle on done
    _socketStream.transform(_streamBuffer).forEach(handleXmlStream);
    _socket.getErrorStream().listen(_handleError);

    _uuid = const Uuid();
  }

  /// Registers an [XmppManagerBase] subclass as a manager on this connection
  void registerManager(XmppManagerBase manager) {
    _log.finest("Registering ${manager.getId()}");
    manager.register(XmppManagerAttributes(
        sendStanza: sendStanza,
        sendNonza: sendRawXML,
        sendRawXml: _socket.write,
        sendEvent: _sendEvent,
        getConnectionSettings: () => _connectionSettings,
        getManagerById: getManagerById,
        isStreamFeatureSupported: isStreamFeatureSupported,
        isFeatureSupported: (feature) => _serverFeatures.contains(feature),
        getFullJID: () => _connectionSettings.jid.withResource(_resource)
    ));

    final id = manager.getId();
    _xmppManagers[id] = manager;

    if (id == discoManager) {
      // NOTE: It is intentional that we do not exclude the [DiscoManager] from this
      //       loop. It may also register features.
      for (var man in _xmppManagers.values) {
        (manager as DiscoManager).addDiscoFeatures(man.getDiscoFeatures());
      }
    } else if (_xmppManagers.containsKey(discoManager)) {
      (_xmppManagers[discoManager] as DiscoManager).addDiscoFeatures(manager.getDiscoFeatures());
    }
  }

  /// Generate an Id suitable for an origin-id or stanza id
  String generateId() {
    return _uuid.v4();
  }
  
  /// Returns the Manager with id [id] or null if such a manager is not registered.
  T? getManagerById<T>(String id) {
    final manager = _xmppManagers[id];
    if (manager != null) {
      return manager as T;
    }

    return null;
  }

  /// A [PresenceManager] is required, so have a wrapper for getting it.
  /// Returns the registered [PresenceManager].
  PresenceManager getPresenceManager() {
    assert(_xmppManagers.containsKey(presenceManager));

    return getManagerById(presenceManager)!;
  }

  /// A [DiscoManager] is required so, have a wrapper for getting it.
  /// Returns the registered [DiscoManager].
  DiscoManager getDiscoManager() {
    assert(_xmppManagers.containsKey(discoManager));

    return getManagerById(discoManager)!;
  }

  /// A [DiscoCacheManager] is required, so have a wrapper for getting it.
  /// Returns the registered [DiscoCacheManager].
  DiscoCacheManager getDiscoCacheManager() {
    assert(_xmppManagers.containsKey(discoCacheManager));

    return getManagerById(discoCacheManager)!;
  }

  /// A [RosterManager] is required, so have a wrapper for getting it.
  /// Returns the registered [DiscoCacheManager].
  RosterManager getRosterManager() {
    assert(_xmppManagers.containsKey(rosterManager));

    return getManagerById(rosterManager)!;
  }
  
  /// Returns the registered [StreamManagementManager], if one is registered.
  StreamManagementManager? getStreamManagementManager() {
    return getManagerById(smManager);
  }

  /// Returns the registered [CSIManager], if one is registered.
  CSIManager? getCSIManager() {
    return getManagerById(csiManager);
  }
  
  /// Set the connection settings of this connection.
  void setConnectionSettings(ConnectionSettings settings) {
    _connectionSettings = settings;
  }
  /// Returns the connection settings of this connection.
  ConnectionSettings getConnectionSettings() {
    return _connectionSettings;
  }
  
  void _handleError(Object? error) {
    _log.severe((error ?? "").toString());

    // TODO: This may be too harsh for every error
    _setConnectionState(XmppConnectionState.notConnected);
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

  /// Returns the [ConnectionState] of the connection
  XmppConnectionState getConnectionState() => _connectionState;
  
  /// Returns true if the stream supports the XMLNS @feature.
  bool isStreamFeatureSupported(String feature) {
    return _streamFeatures.contains(feature);
  }

  /// Sends an [XMLNode] without any further processing to the server.
  void sendRawXML(XMLNode node) {
    _socket.write(node.toXml());
  }

  /// Returns true if we can send data through the socket.
  bool _canSendData() {
    return [
      XmppConnectionState.connected,
      XmppConnectionState.connecting
    ].contains(_connectionState);
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
      stanza = stanza.copyWith(id: generateId());
    }
    if (addFrom && (stanza.from == null || stanza.from == "")) {
      stanza = stanza.copyWith(from: _connectionSettings.jid.withResource(_resource).toString());
    }

    final stanzaString = stanza.toXml();
    
    _awaitingResponse[stanza.id!] = Completer();

    // This uses the StreamManager to behave like a send queue
    if (_canSendData()) {
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
  void _setConnectionState(XmppConnectionState state) {
    _connectionState = state;
    _eventStreamController.add(ConnectionStateChangedEvent(state: state, resumed: _resuming));

    if (state == XmppConnectionState.connected) {
      _connectionPingTimer = Timer.periodic(connectionPingDuration, _pingConnectionOpen);
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
      _log.severe("Resource binding failed!");
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
    if (_connectionState == XmppConnectionState.connected) {
      _sendEvent(SendPingEvent());
    }
  }

  Future<void> _discoverServerFeatures() async {
    _serverFeatures.clear();
    final serverJid = _connectionSettings.jid.domain;
    final serverInfo = await getDiscoCacheManager().getInfoByJid(serverJid);
    if (serverInfo != null) {
      _log.finest("Discovered supported server features: ${serverInfo.features}");
      _serverFeatures.addAll(serverInfo.features);
      _sendEvent(ServerDiscoDoneEvent());
    } else {
      _log.warning("Failed to discover server features using XEP-0030");
    }

    final serverItems = await getDiscoManager().discoItemsQuery(serverJid);
    if (serverItems != null) {
      _log.finest("Received disco items for $serverJid");
      for (final item in serverItems) {
        _log.finest("Querying info for ${item.jid}");
        final info = await getDiscoCacheManager().getInfoByJid(item.jid);
        if (info != null) {
          _log.finest("Received info for ${item.jid}");
          _sendEvent(ServerItemDiscoEvent(info: info, jid: item.jid));
        } else {
          _log.warning("Failed to discover disco info for ${item.jid}");
        }
      }
    } else {
      _log.warning("Failed to discover server items using XEP-0030");
    }
  }
  
  /// Called whenever we receive a stanza after resource binding or stream resumption.
  Future<void> _handleStanza(XMLNode nonza) async {
    // Process nonzas separately
    if (!["message", "iq", "presence"].contains(nonza.tag)) {
      bool nonzaHandled = false;
      await Future.forEach(
        _xmppManagers.values,
        (XmppManagerBase manager) async {
          final handled = await manager.runNonzaHandlers(nonza);

          if (!nonzaHandled && handled) nonzaHandled = true;
        }
      );

      if (!nonzaHandled) {
        _log.warning("Unhandled nonza received: " + nonza.toXml());
      }
      return;
    }

    final stanza = Stanza.fromXMLNode(nonza);
    final id = stanza.attributes["id"];
    if (id != null && _awaitingResponse.containsKey(id)) {
      _awaitingResponse[id]!.complete(stanza);
      _awaitingResponse.remove(id);
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
    _log.finest("<== " + node.toXml());

    if (node.tag == "stream:stream" && node.children.isEmpty) {
      _handleError(null);
      return;
    }
    
    switch (_routingState) {
      case RoutingState.unauthenticated: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          _log.severe("Expected stream header");
          _routingState = RoutingState.error;
          return;
        }

        final streamFeatures = node.firstTag("stream:features")!;

        // First check for StartTLS
        final startTLS = streamFeatures.firstTag("starttls", xmlns: startTlsXmlns);
        if (startTLS != null) {
          _routingState = RoutingState.performStartTLS;
          sendRawXML(StartTLSNonza());
          return;
        }

        if (!_socket.isSecure()) {
          _log.severe("Refusing to go any further on an insecure connection");
          _routingState = RoutingState.error;
          _setConnectionState(XmppConnectionState.error);
          return;
        }
        
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
          _log.severe("SASL failed");
          _sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          _setConnectionState(XmppConnectionState.error);
          _routingState = RoutingState.error;
        }
      }
      break;
      case RoutingState.performStartTLS: {
        if (node.tag != "proceed" || node.attributes["xmlns"] != startTlsXmlns) {
          _log.severe("Failed to proceed with StartTLS negotiation");
          _routingState = RoutingState.error;
          _setConnectionState(XmppConnectionState.error);
          return;
        }

        _log.finest("Securing socket...");
        final result = await _socket.secure();
        if (!result) {
          _log.severe("Failed to secure the socket");
          _routingState = RoutingState.error;
          _setConnectionState(XmppConnectionState.error);
          return;
        }
        _log.finest("Done!");

        _routingState = RoutingState.unauthenticated;
        _sendStreamHeader();
      }
      break;
      case RoutingState.performSaslAuth: {
        final result = await _authenticator.next(node);
        if (result.getState() == AuthenticationResult.success) {
          _routingState = RoutingState.checkStreamManagement;
          _sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.failure) {
          _log.severe("SASL failed");
          _sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          _setConnectionState(XmppConnectionState.error);
          _routingState = RoutingState.error;
        }
      }
      break;
      case RoutingState.checkStreamManagement: {
        // We expect the stream header here
        if (node.tag != "stream:stream") {
          _log.severe("Expected stream header");
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

        final streamManager = getStreamManagementManager();
        if (isStreamFeatureSupported(smXmlns) && streamManager != null) {
          await streamManager.loadStreamResumptionId();
          await streamManager.loadState();
          final srid = streamManager.getStreamResumptionId();
          final h = streamManager.getS2CStanzaCount();
          
          // Try to work with SM first
          if (srid != null) {
            // Try to resume the last stream
            _routingState = RoutingState.performStreamResumption;
            sendRawXML(StreamManagementResumeNonza(srid, h));
          } else {
            // Try to enable SM
            _resuming = false;
            _routingState = RoutingState.bindResourcePreSM;
            _performResourceBinding();
          }
        } else {
          _resuming = false;
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
          _log.severe("Resource binding failed!");
          _routingState = RoutingState.error;
          _setConnectionState(XmppConnectionState.error);
        }

        _discoverServerFeatures();
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
          _log.fine("Stream Resumption successful!");
          // NOTE: _resource is already set if we resume
          assert(_resource != "");
          _routingState = RoutingState.handleStanzas;
          _setConnectionState(XmppConnectionState.connected);

          // Restore the CSI state if we have a manager
          final csiManager = getCSIManager();
          if (csiManager != null) {
            csiManager.restoreCSIState();
          }
          
          final h = int.parse(node.attributes["h"]!);
          _sendEvent(StreamResumedEvent(h: h));

          if (_serverFeatures.isEmpty) _discoverServerFeatures();
        } else if (node.tag == "failed") {
          // NOTE: If we are here, we have it.
          final manager = getStreamManagementManager()!;
          _log.fine("Stream resumption failed. Proceeding with new stream...");

          // We have to do this because we otherwise get a stanza stuck in the queue,
          // thus spamming the server on every <a /> nonza we receive.
          manager.setState(0, 0);
          await manager.commitState();

          _serverFeatures.clear();
          _resuming = false;
          _routingState = RoutingState.bindResourcePreSM;
          _performResourceBinding();
        }
      }
      break;
      case RoutingState.enableSM: {
        if (node.tag == "failed") {
          // Not critical
          _log.warning("Failed to enable SM: " + node.tag);
          _routingState = RoutingState.handleStanzas;
          getPresenceManager().sendInitialPresence();
        } else if (node.tag == "enabled") {
          _log.fine("SM enabled!");

          final id = node.attributes["id"];
          if (id != null && [ "true", "1" ].contains(node.attributes["resume"])) {
            _log.finest("Stream resumption possible!");
            _sendEvent(StreamManagementEnabledEvent(id: id, resource: _resource));
          }

          _routingState = RoutingState.handleStanzas;
          getPresenceManager().sendInitialPresence();
          _setConnectionState(XmppConnectionState.connected);
        }
 
        _discoverServerFeatures();
      }
      break;
      case RoutingState.handleStanzas: {
        await _handleStanza(node);
      }
      break;
      case RoutingState.error: {
        _log.warning("Received node while in error state. Ignoring: ${node.toXml()}");
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
    _setConnectionState(XmppConnectionState.notConnected);
  }

  /// To be called when we lost network connection
  Future<void> onNetworkConnectionRegained() async {
    if (_connectionState == XmppConnectionState.notConnected) {
      connect();
    }
  }
  
  /// Start the connection process using the provided connection settings.
  Future<void> connect({ String? lastResource }) async {
    assert(_xmppManagers.containsKey(presenceManager));
    assert(_xmppManagers.containsKey(rosterManager));
    assert(_xmppManagers.containsKey(discoManager));

    // TODO: Remove once StartTLS is implemented
    assert(_connectionSettings.useDirectTLS == true);
    
    if (lastResource != null) {
      _resource = lastResource;
    }
    
    if (_backoffTimer != null) {
      _backoffTimer!.cancel();
      _backoffTimer = null;
    }

    _resuming = true;
    _sendEvent(ConnectingEvent());

    final result = await _socket.connect(_connectionSettings.jid.domain);
    if (!result) {
      _handleError(null);
    } else {
      _currentBackoffAttempt = 0; 
      _setConnectionState(XmppConnectionState.connecting);
      _routingState = RoutingState.unauthenticated;
      _sendStreamHeader();
    }
  }
}
