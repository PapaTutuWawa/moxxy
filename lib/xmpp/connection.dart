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
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/nonzas.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/state.dart";

import "package:uuid/uuid.dart";
import "package:logging/logging.dart";

enum XmppConnectionState {
  notConnected,
  connecting,
  connected,
  error
}

enum StanzaFromType {
  // Add the full JID to the stanza as the from attribute
  full,
  // Add the bare JID to the stanza as the from attribute
  bare,
  // Add no JID as the from attribute
  none
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

class XmppConnectionResult {
  final bool success;
  // NOTE: [reason] is not human-readable, but the type of SASL error.
  //       See sasl/errors.dart
  final String? reason;

  const XmppConnectionResult(
    this.success,
    {
      this.reason
    }
  );
}

class XmppConnection {
  final StreamController<XmppEvent> _eventStreamController;
  final Map<String, Completer<XMLNode>> _awaitingResponse;
  final Map<String, XmppManagerBase> _xmppManagers;
  final List<StanzaHandler> _incomingStanzaHandlers;
  final List<StanzaHandler> _outgoingStanzaHandlers;
  final BaseSocketWrapper _socket;
  XmppConnectionState _connectionState;
  late final Stream<String> _socketStream;
  late ConnectionSettings _connectionSettings;
  
  /// Stream properties
  ///
  /// Features we got after SASL auth (xmlns)
  final List<String> _streamFeatures = List.empty(growable: true);
  /// Disco info we got after binding a resource (xmlns)
  final List<String> _serverFeatures = List.empty(growable: true);
  /// The buffer object to keep split up stanzas together
  final XmlStreamBuffer _streamBuffer;
  /// UUID object to generate stanza and origin IDs
  final Uuid _uuid;
  /// The time between sending a ping to keep the connection open
  // TODO: Only start the timer if we did not send a stanza after n seconds
  final Duration connectionPingDuration;
  /// The current state of the connection handling state machine.
  RoutingState _routingState;
  /// The currently bound resource or "" if none has been bound yet.
  String _resource;
  /// Counter for how manyy we have tried to reconnect.
  int _currentBackoffAttempt;
  /// For indicating in a [ConnectionStateChangedEvent] that the event occured because we
  /// did a reconnection.
  bool _resuming;
  /// For indicating whether we expect the socket to close to prevent accidentally
  /// triggering a reconnection attempt when we don't want to.
  bool _disconnecting;
  /// For indicating whether we expect a socket closure due to StartTLS.
  bool _performingStartTLS;
  /// Timers for the keep-alive ping and the backoff connection process.
  Timer? _connectionPingTimer;
  Timer? _backoffTimer;
  /// Completers for certain actions
  Completer<XmppConnectionResult>? _connectionCompleter;

  /// Negotiators
  late AuthenticationNegotiator _authenticator;

  /// Misc
  final Logger _log;

  /// [socket] is for debugging purposes.
  /// [connectionPingDuration] is the duration after which a ping will be sent to keep
  /// the connection open. Defaults to 15 minutes.
  XmppConnection({
      BaseSocketWrapper? socket,
      this.connectionPingDuration = const Duration(minutes: 15)
  }) :
    _connectionState = XmppConnectionState.notConnected,
    _routingState = RoutingState.unauthenticated,
    _eventStreamController = StreamController(),
    _resource = "",
    _streamBuffer = XmlStreamBuffer(),
    _currentBackoffAttempt = 0,
    _resuming = true,
    _performingStartTLS = false,
    _disconnecting = false,
    _uuid = const Uuid(),
    // NOTE: For testing 
    _socket = socket ?? TCPSocketWrapper(),
    _awaitingResponse = {},
    _xmppManagers = {},
    _incomingStanzaHandlers = List.empty(growable: true),
    _outgoingStanzaHandlers = List.empty(growable: true),
    _log = Logger("XmppConnection") {
    _socketStream = _socket.getDataStream();
    // TODO: Handle on done
    _socketStream.transform(_streamBuffer).forEach(handleXmlStream);
    _socket.getEventStream().listen(_handleSocketEvent);
  }

  List<String> get streamFeatures => _streamFeatures;
  List<String> get serverFeatures => _serverFeatures;
  
  /// Registers an [XmppManagerBase] sub-class as a manager on this connection.
  /// [sortHandlers] should NOT be touched. It specified if the handler priorities
  /// should be set up. The only time this should be false is when called via
  /// [registerManagers].
  void registerManager(XmppManagerBase manager, { bool sortHandlers = true }) {
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

    _incomingStanzaHandlers.addAll(manager.getIncomingStanzaHandlers());
    _outgoingStanzaHandlers.addAll(manager.getOutgoingStanzaHandlers());
    
    if (sortHandlers) {
      _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
      _outgoingStanzaHandlers.sort(stanzaHandlerSortComparator);
    }
  }

  /// Like [registerManager], but for a list of managers.
  void registerManagers(List<XmppManagerBase> managers) {
    for (final manager in managers) {
      registerManager(manager, sortHandlers: false);
    }

    // Sort them
    _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingStanzaHandlers.sort(stanzaHandlerSortComparator);
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

  /// Attempts to reconnect to the server by following an exponential backoff.
  void _attemptReconnection() {
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
  
  /// Called when a stream ending error has occurred
  void _handleError(Object? error) {
    if (error != null) {
      _log.severe("_handleError: $error");
    } else {
      _log.severe("_handleError: Called with null");
    } 

    // TODO: This may be too harsh for every error
    _attemptReconnection();
  }

  /// Called whenever the socket creates an event
  void _handleSocketEvent(XmppSocketEvent event) {
    if (event is XmppSocketErrorEvent) {
      _handleError(event.error);
    } else if (event is XmppSocketClosureEvent) {
      // Only reconnect if we didn't expect this
      if (!_disconnecting && !_performingStartTLS) {
        _log.fine("Received XmppSocketClosureEvent, but _disconnecting is false. Reconnecting...");
        _attemptReconnection();
      }
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

  /// Sends [raw] to the server.
  void sendRawString(String raw) {
    _socket.write(raw);
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
  Future<XMLNode> sendStanza(Stanza stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool awaitable = true, bool retransmitted = false }) async {
    // Add extra data in case it was not set
    if (addId && (stanza.id == null || stanza.id == "")) {
      stanza = stanza.copyWith(id: generateId());
    }
    if (addFrom != StanzaFromType.none && (stanza.from == null || stanza.from == "")) {
      switch (addFrom) {
        case StanzaFromType.full: {
          stanza = stanza.copyWith(from: _connectionSettings.jid.withResource(_resource).toString());
        }
        break;
        case StanzaFromType.bare: {
          stanza = stanza.copyWith(from: _connectionSettings.jid.toBare().toString());
        }
        break;
        case StanzaFromType.none: break;
      }
    }

    final stanzaString = stanza.toXml();

    if (awaitable) {
      _awaitingResponse[stanza.id!] = Completer();
    }

    // Tell the SM manager that we're about to send a stanza
    await _runOutoingStanzaHandlers(stanza, initial: StanzaHandlerData(false, stanza, retransmitted: retransmitted));
    
    // This uses the StreamManager to behave like a send queue
    final canSendData = _canSendData();
    if (canSendData) {
      _socket.write(stanzaString);

      // Try to ack every stanza
      // NOTE: Here we have send an Ack request nonza. This is now done by StreamManagementManager when receiving the StanzaSentEvent
    } else {
      _log.fine("_canSendData() returned false since _connectionState == $_connectionState");
    }

    if (awaitable) {
      return _awaitingResponse[stanza.id!]!.future;
    } else {
      return Future.value(XMLNode(tag: "not-used"));
    }
  }

  /// Sets the connection state to [state] and triggers an event of type
  /// [ConnectionStateChangedEvent].
  void _setConnectionState(XmppConnectionState state) {
    _log.finest("Updating _connectionState from $_connectionState to $state");
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

  /// Sets the routing state and logs the change
  void _updateRoutingState(RoutingState state) {
    _log.finest("Updating _routingState from $_routingState to $state");
    _routingState = state;
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
      addFrom: StanzaFromType.none
    );
  }

  /// Handles the result to the resource binding request and returns true if we should
  /// proceed and false if not.
  bool _handleResourceBindingResult(XMLNode stanza) {
    if (stanza.tag != "iq" || stanza.attributes["type"] != "result") {
      _log.severe("Resource binding failed!");
      _updateRoutingState(RoutingState.error);
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

  /// Iterate over [handlers] and check if the handler matches [stanza]. If it does,
  /// call its callback and end the processing if the callback returned true; continue
  /// if it returned false.
  Future<bool> _runStanzaHandlers(List<StanzaHandler> handlers, Stanza stanza, { StanzaHandlerData? initial }) async {
    StanzaHandlerData state = initial ?? StanzaHandlerData(false, stanza);
    for (final handler in handlers) {
      if (handler.matches(state.stanza)) {
        state = await handler.callback(state.stanza, state);
        if (state.done) return true;
      }
    }

    return false;
  }

  Future<bool> _runIncomingStanzaHandlers(Stanza stanza) async {
    return await _runStanzaHandlers(
      _incomingStanzaHandlers,
      stanza
    );
  }
  Future<bool> _runOutoingStanzaHandlers(Stanza stanza, { StanzaHandlerData? initial }) async {
    return await _runStanzaHandlers(
      _outgoingStanzaHandlers,
      stanza,
      initial: initial
    );
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

    final stanzaHandled = await _runIncomingStanzaHandlers(stanza);

    if (!stanzaHandled) {
      handleUnhandledStanza(this, stanza);
    }
  }

  /// Called whenever we receive data that has been parsed as XML.
  void handleXmlStream(XMLNode node) async {
    switch (_routingState) {
      case RoutingState.unauthenticated: {
        // We expect the stream header here
        if (node.tag != "stream:features") {
          _log.severe("Expected stream features");
          _routingState = RoutingState.error;
          return;
        }

        final streamFeatures = node;

        // First check for StartTLS
        final startTLS = streamFeatures.firstTag("starttls", xmlns: startTlsXmlns);
        if (startTLS != null) {
          _log.fine("StartTLS is availabe. Performing StartTLS upgrade.");
          _updateRoutingState(RoutingState.performStartTLS);
          sendRawXML(StartTLSNonza());
          return;
        }

        if (!_socket.isSecure()) {
          _log.severe("Refusing to go any further on an insecure connection");
          _updateRoutingState(RoutingState.error);
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
          _log.severe("Failed to select an authenticator!");
          _updateRoutingState(RoutingState.error);
          return;
        } else {
          _authenticator = authenticator;
        }

        _log.fine("Proceeding with SASL authentication");
        _updateRoutingState(RoutingState.performSaslAuth);
        final result = await _authenticator.next(null);
        if (result.getState() == AuthenticationResult.success) {
          _log.fine("SASL authentication was successful. Proceeding to check stream features");
          _updateRoutingState(RoutingState.checkStreamManagement);
          _sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.failure) {
          _log.severe("SASL authentication failed!");
          _sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          _setConnectionState(XmppConnectionState.error);
          _updateRoutingState(RoutingState.error);

          if (_connectionCompleter != null) {
            _connectionCompleter!.complete(
              XmppConnectionResult(
                false,
                reason: result.getValue()
              )
            );
            _connectionCompleter = null;
          }
        }
      }
      break;
      case RoutingState.performStartTLS: {
        if (node.tag != "proceed" || node.attributes["xmlns"] != startTlsXmlns) {
          _log.severe("Failed to proceed with StartTLS negotiation");
          _updateRoutingState(RoutingState.error);
          _setConnectionState(XmppConnectionState.error);
          return;
        }

        _performingStartTLS = true;
        _log.fine("Securing socket...");
        final result = await _socket.secure(_connectionSettings.jid.domain);
        if (!result) {
          _log.severe("Failed to secure the socket");
          _updateRoutingState(RoutingState.error);
          _setConnectionState(XmppConnectionState.error);
          return;
        }
        _log.fine("Done!");
        _log.fine("Restarting stream negotiation on TLS secured stream.");
        _performingStartTLS = false;
        _updateRoutingState(RoutingState.unauthenticated);
        _sendStreamHeader();
      }
      break;
      case RoutingState.performSaslAuth: {
        final result = await _authenticator.next(node);
        if (result.getState() == AuthenticationResult.success) {
          _log.fine("SASL authentication was successful. Proceeding to check stream features");
          _updateRoutingState(RoutingState.checkStreamManagement);
          _sendStreamHeader();
        } else if (result.getState() == AuthenticationResult.failure) {
          _log.severe("SASL authentication failed!");
          _sendEvent(AuthenticationFailedEvent(saslError: result.getValue()));
          _setConnectionState(XmppConnectionState.error);
          _updateRoutingState(RoutingState.error);
        }
      }
      break;
      case RoutingState.checkStreamManagement: {
        if (node.tag != "stream:features") {
          _log.severe("Expected stream features");
          _routingState = RoutingState.error;
          return;
        }

        final streamFeatures = node;
        // TODO: Handle required features?
        // NOTE: In case of reconnecting
        _streamFeatures.clear();
        for (var node in streamFeatures.children) {
          _streamFeatures.add(node.attributes["xmlns"]);
        }

        final streamManager = getStreamManagementManager();
        if (isStreamFeatureSupported(smXmlns) && streamManager != null) {
          await streamManager.loadState();
          final srid = streamManager.state.streamResumptionId;
          final h = streamManager.state.s2c;
          
          // Try to work with SM first
          if (srid != null) {
            // Try to resume the last stream
            _log.fine("Found stream resumption Id. Attempting to perform stream resumption");
            _updateRoutingState(RoutingState.performStreamResumption);
            sendRawXML(StreamManagementResumeNonza(srid, h));
          } else {
            // Try to enable SM
            _resuming = false;
            _log.fine("Attempting to bind resource before enabling Stream Management");
            _updateRoutingState(RoutingState.bindResourcePreSM);
            _performResourceBinding();
          }
        } else {
          _resuming = false;
          _log.fine("Either there is no StreamManagementManager registered or the stream does not support Stream Management.");
          _log.fine("Proceeding to bind resource");
          _updateRoutingState(RoutingState.bindResource);
          _performResourceBinding();
        }
      }
      break;
      case RoutingState.bindResource: {
        final proceed = _handleResourceBindingResult(node);
        if (proceed) {
          _log.fine("Stream negotiation done. Ready to handle stanzas");
          _updateRoutingState(RoutingState.handleStanzas);
          getPresenceManager().sendInitialPresence();
          if (_connectionCompleter != null) {
            _connectionCompleter!.complete(
              const XmppConnectionResult(true)
            );
            _connectionCompleter = null;
          }
        } else {
          _log.severe("Resource binding failed!");
          _updateRoutingState(RoutingState.error);
          _setConnectionState(XmppConnectionState.error);
          return;
        }

        _discoverServerFeatures();
      }
      break;
      case RoutingState.bindResourcePreSM: {
        final proceed = _handleResourceBindingResult(node);
        if (proceed) {
          if (_connectionCompleter != null) {
            _connectionCompleter!.complete(
              const XmppConnectionResult(true)
            );
            _connectionCompleter = null;
          }

          _log.fine("Attempting to enable Stream Management");
          _updateRoutingState(RoutingState.enableSM);
          sendRawXML(StreamManagementEnableNonza());
        }
      }
      break;
      case RoutingState.performStreamResumption: {
        if (node.tag == "resumed") {
          _log.fine("Stream Resumption successful!");
          // NOTE: _resource is already set if we resume
          assert(_resource != "");
          _updateRoutingState(RoutingState.handleStanzas);
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
          _log.info("Stream resumption failed. Proceeding with new stream...");

          // We have to do this because we otherwise get a stanza stuck in the queue,
          // thus spamming the server on every <a /> nonza we receive.
          manager.setState(StreamManagementState(0, 0));
          await manager.commitState();

          _serverFeatures.clear();
          _resuming = false;
          _updateRoutingState(RoutingState.bindResourcePreSM);
          _performResourceBinding();
        }
      }
      break;
      case RoutingState.enableSM: {
        if (node.tag == "failed") {
          // Not critical
          _log.warning("Failed to enable SM: " + node.tag);
          _updateRoutingState(RoutingState.handleStanzas);
          getPresenceManager().sendInitialPresence();
        } else if (node.tag == "enabled") {
          _log.fine("SM enabled!");

          final id = node.attributes["id"];
          if (id != null && [ "true", "1" ].contains(node.attributes["resume"])) {
            _log.finest("Stream resumption possible!");
          }

          _sendEvent(
            StreamManagementEnabledEvent(
              resource: _resource,
              id: node.attributes["id"],
              location: node.attributes["location"]
            )
          );

          _updateRoutingState(RoutingState.handleStanzas);
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
    _log.finest("Event: ${event.toString()}");

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

  /// Attempt to gracefully close the session
  Future<void> disconnect() async {
    _disconnecting = true;
    getPresenceManager().sendUnavailablePresence();
    sendRawString("</stream:stream>");
    _setConnectionState(XmppConnectionState.notConnected);
    _socket.close();

    // Clear Stream Management state, if available
    await getStreamManagementManager()?.resetState();
  }
  
  /// Like [connect] but the Future resolves when the resource binding is either done or
  /// SASL has failed.
  Future<XmppConnectionResult> connectAwaitable({ String? lastResource }) {
    _connectionCompleter = Completer();
    connect(lastResource: lastResource);
    return _connectionCompleter!.future;
  }
  
  /// Start the connection process using the provided connection settings.
  Future<void> connect({ String? lastResource }) async {
    assert(_xmppManagers.containsKey(presenceManager));
    assert(_xmppManagers.containsKey(rosterManager));
    assert(_xmppManagers.containsKey(discoManager));

    _disconnecting = false;
    
    if (lastResource != null) {
      _resource = lastResource;
    }
    
    if (_backoffTimer != null) {
      _backoffTimer!.cancel();
      _backoffTimer = null;
    }

    _resuming = true;
    _sendEvent(ConnectingEvent());

    final smManager = getStreamManagementManager();
    String? host;
    int? port;
    if (smManager?.state.streamResumptionLocation != null) {
      // TODO: Maybe wrap this in a try catch?
      final parsed = Uri.parse(smManager!.state.streamResumptionLocation!);
      host = parsed.host;
      port = parsed.port;
    }
    
    final result = await _socket.connect(
      _connectionSettings.jid.domain,
      host: host,
      port: port
    );
    if (!result) {
      _handleError(null);
    } else {
      _currentBackoffAttempt = 0;
      _log.fine("Preparing the internal state for a connection attempt");
      _performingStartTLS = false;
      _setConnectionState(XmppConnectionState.connecting);
      _updateRoutingState(RoutingState.unauthenticated);
      _sendStreamHeader();
    }
  }
}
