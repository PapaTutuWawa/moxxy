import 'dart:async';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/buffer.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/iq.dart';
import 'package:moxxyv2/xmpp/managers/attributes.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/presence.dart';
import 'package:moxxyv2/xmpp/reconnect.dart';
import 'package:moxxyv2/xmpp/roster.dart';
import 'package:moxxyv2/xmpp/routing.dart';
import 'package:moxxyv2/xmpp/settings.dart';
import 'package:moxxyv2/xmpp/socket.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0352.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

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
      tag: 'stream:stream',
      attributes: <String, String>{
        'xmlns': stanzaXmlns,
        'version': '1.0',
        'xmlns:stream': streamXmlns,
        'to': serverDomain,
        'xml:lang': 'en',
      },
      closeTag: false,
    );
}

class XmppConnectionResult {
  const XmppConnectionResult(
    this.success,
    {
      this.reason,
    }
  );

  final bool success;
  // NOTE: [reason] is not human-readable, but the type of SASL error.
  //       See sasl/errors.dart
  final String? reason;
}

class XmppConnection {
  /// [socket] is for debugging purposes.
  /// [connectionPingDuration] is the duration after which a ping will be sent to keep
  /// the connection open. Defaults to 15 minutes.
  XmppConnection(
    ReconnectionPolicy reconnectionPolicy,
    {
      BaseSocketWrapper? socket,
      this.connectionPingDuration = const Duration(minutes: 5),
    }
  ) :
    _connectionState = XmppConnectionState.notConnected,
    _routingState = RoutingState.preConnection,
    _eventStreamController = StreamController.broadcast(),
    _resource = '',
    _streamBuffer = XmlStreamBuffer(),
    _resuming = true,
    _performingStartTLS = false,
    _disconnecting = false,
    _uuid = const Uuid(),
    _socket = socket ?? TCPSocketWrapper(),
    _awaitingResponse = {},
    _awaitingResponseLock = Lock(),
    _xmppManagers = {},
    _incomingStanzaHandlers = List.empty(growable: true),
    _outgoingPreStanzaHandlers = List.empty(growable: true),
    _outgoingPostStanzaHandlers = List.empty(growable: true),
    _reconnectionPolicy = reconnectionPolicy,
    _featureNegotiators = {},
    _streamFeatures = List.empty(growable: true),
    _log = Logger('XmppConnection') {
      // Allow the reconnection policy to perform reconnections by itself
      _reconnectionPolicy.register(
        _attemptReconnection,
        _onNetworkConnectionLost,
      );

      _socketStream = _socket.getDataStream();
      // TODO(Unknown): Handle on done
      _socketStream.transform(_streamBuffer).forEach(handleXmlStream);
      _socket.getEventStream().listen(_handleSocketEvent);
  }

  final StreamController<XmppEvent> _eventStreamController;
  final Map<String, Completer<XMLNode>> _awaitingResponse;
  final Lock _awaitingResponseLock;
  final Map<String, XmppManagerBase> _xmppManagers;
  final List<StanzaHandler> _incomingStanzaHandlers;
  final List<StanzaHandler> _outgoingPreStanzaHandlers;
  final List<StanzaHandler> _outgoingPostStanzaHandlers;
  final BaseSocketWrapper _socket;
  XmppConnectionState _connectionState;
  late final Stream<String> _socketStream;
  late ConnectionSettings _connectionSettings;
  final ReconnectionPolicy _reconnectionPolicy;
  
  /// Stream properties
  ///
  /// Disco info we got after binding a resource (xmlns)
  final List<String> _serverFeatures = List.empty(growable: true);
  /// The buffer object to keep split up stanzas together
  final XmlStreamBuffer _streamBuffer;
  /// UUID object to generate stanza and origin IDs
  final Uuid _uuid;
  /// The time between sending a ping to keep the connection open
  // TODO(Unknown): Only start the timer if we did not send a stanza after n seconds
  final Duration connectionPingDuration;
  /// The current state of the connection handling state machine.
  RoutingState _routingState;
  /// The currently bound resource or '' if none has been bound yet.
  String _resource;
  /// For indicating in a [ConnectionStateChangedEvent] that the event occured because we
  /// did a reconnection.
  bool _resuming;
  /// For indicating whether we expect the socket to close to prevent accidentally
  /// triggering a reconnection attempt when we don't want to.
  bool _disconnecting;
  /// For indicating whether we expect a socket closure due to StartTLS.
  bool _performingStartTLS;
  /// Timers for the keep-alive ping.
  Timer? _connectionPingTimer;
  /// Completers for certain actions
  // ignore: use_late_for_private_fields_and_variables
  Completer<XmppConnectionResult>? _connectionCompleter;

  /// Negotiators
  final Map<String, XmppFeatureNegotiatorBase> _featureNegotiators;
  XmppFeatureNegotiatorBase? _currentNegotiator;
  final List<XMLNode> _streamFeatures;
  
  /// Misc
  final Logger _log;

  ReconnectionPolicy get reconnectionPolicy => _reconnectionPolicy;
  
  List<String> get serverFeatures => _serverFeatures;

  /// Return the registered feature negotiator that has id [id]. Returns null if
  /// none can be found.
  XmppFeatureNegotiatorBase? getNegotiatorById(String id) => _featureNegotiators[id];
  
  /// Registers an [XmppManagerBase] sub-class as a manager on this connection.
  /// [sortHandlers] should NOT be touched. It specified if the handler priorities
  /// should be set up. The only time this should be false is when called via
  /// [registerManagers].
  void registerManager(XmppManagerBase manager, { bool sortHandlers = true }) {
    _log.finest('Registering ${manager.getId()}');
    manager.register(
      XmppManagerAttributes(
        sendStanza: sendStanza,
        sendNonza: sendRawXML,
        sendRawXml: _socket.write,
        sendEvent: _sendEvent,
        getConnectionSettings: () => _connectionSettings,
        getManagerById: getManagerById,
        isFeatureSupported: _serverFeatures.contains,
        getFullJID: () => _connectionSettings.jid.withResource(_resource),
        getSocket: () => _socket,
        getConnection: () => this,
        getNegotiatorById: getNegotiatorById,
      ),
    );

    final id = manager.getId();
    _xmppManagers[id] = manager;

    if (id == discoManager) {
      // NOTE: It is intentional that we do not exclude the [DiscoManager] from this
      //       loop. It may also register features.
      for (final registeredManager in _xmppManagers.values) {
        (manager as DiscoManager).addDiscoFeatures(registeredManager.getDiscoFeatures());
      }
    } else if (_xmppManagers.containsKey(discoManager)) {
      (_xmppManagers[discoManager]! as DiscoManager).addDiscoFeatures(manager.getDiscoFeatures());
    }

    _incomingStanzaHandlers.addAll(manager.getIncomingStanzaHandlers());
    _outgoingPreStanzaHandlers.addAll(manager.getOutgoingPreStanzaHandlers());
    _outgoingPostStanzaHandlers.addAll(manager.getOutgoingPostStanzaHandlers());
    
    if (sortHandlers) {
      _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
      _outgoingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
      _outgoingPostStanzaHandlers.sort(stanzaHandlerSortComparator);
    }
  }

  /// Like [registerManager], but for a list of managers.
  void registerManagers(List<XmppManagerBase> managers) {
    for (final manager in managers) {
      registerManager(manager, sortHandlers: false);
    }

    // Sort them
    _incomingStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingPreStanzaHandlers.sort(stanzaHandlerSortComparator);
    _outgoingPostStanzaHandlers.sort(stanzaHandlerSortComparator);
  }

  /// Register a list of negotiator with the connection.
  void registerFeatureNegotiators(List<XmppFeatureNegotiatorBase> negotiators) {
    for (final negotiator in negotiators) {
      _log.finest('Registering ${negotiator.id}');
      negotiator.register(
        NegotiatorAttributes(
          sendRawXML,
          () => _connectionSettings,
          _sendEvent,
          (id) => _featureNegotiators[id],
          (id) => _xmppManagers[id],
          () => _connectionSettings.jid.withResource(_resource),
          () => _socket,
        ),
      );
      _featureNegotiators[negotiator.id] = negotiator;
    }

    _log.finest('Negotiators registered');
  }

  /// Reset all registered negotiators.
  void _resetNegotiators() {
    for (final negotiator in _featureNegotiators.values) {
      negotiator.reset();
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
    assert(_xmppManagers.containsKey(presenceManager), 'A PresenceManager is mandatory');

    return getManagerById(presenceManager)!;
  }

  /// A [DiscoManager] is required so, have a wrapper for getting it.
  /// Returns the registered [DiscoManager].
  DiscoManager getDiscoManager() {
    assert(_xmppManagers.containsKey(discoManager), 'A DiscoManager is mandatory');

    return getManagerById(discoManager)!;
  }

  /// A [DiscoCacheManager] is required, so have a wrapper for getting it.
  /// Returns the registered [DiscoCacheManager].
  DiscoCacheManager getDiscoCacheManager() {
    assert(_xmppManagers.containsKey(discoCacheManager), 'A DiscoCacheManager is mandatory');

    return getManagerById(discoCacheManager)!;
  }

  /// A [RosterManager] is required, so have a wrapper for getting it.
  /// Returns the registered [DiscoCacheManager].
  RosterManager getRosterManager() {
    assert(_xmppManagers.containsKey(rosterManager), 'A RosterManager is mandatory');

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
    connect();
  }
  
  /// Called when a stream ending error has occurred
  void handleError(Object? error) {
    if (error != null) {
      _log.severe('handleError: $error');
    } else {
      _log.severe('handleError: Called with null');
    } 

    // TODO(Unknown): This may be too harsh for every error
    _reconnectionPolicy.onFailure();
  }

  /// Called whenever the socket creates an event
  void _handleSocketEvent(XmppSocketEvent event) {
    if (event is XmppSocketErrorEvent) {
      handleError(event.error);
    } else if (event is XmppSocketClosureEvent) {
      // Only reconnect if we didn't expect this
      if (!_disconnecting && !_performingStartTLS) {
        _log.fine('Received XmppSocketClosureEvent, but _disconnecting is false. Reconnecting...');
        _attemptReconnection();
      }
    }
  }

  /// NOTE: For debugging purposes only
  /// Returns the internal state of the state machine
  RoutingState getRoutingState() {
    return _routingState;
  }

  /// Returns the ConnectionState of the connection
  XmppConnectionState getConnectionState() => _connectionState;
  
  /// Sends an [XMLNode] without any further processing to the server.
  void sendRawXML(XMLNode node, { String? redact }) {
    _socket.write(node.toXml(), redact: redact);
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
  /// If addFrom is true, then a 'from' attribute will be added to the stanza if
  /// [stanza] has none.
  /// If addId is true, then an 'id' attribute will be added to the stanza if [stanza] has
  /// none.
  // TODO(Unknown): if addId = false, the function crashes.
  Future<XMLNode> sendStanza(Stanza stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool awaitable = true, bool retransmitted = false }) async {
    var stanza_ = stanza;
    
    // Add extra data in case it was not set
    if (addId && (stanza_.id == null || stanza_.id == '')) {
      stanza_ = stanza.copyWith(id: generateId());
    }
    if (addFrom != StanzaFromType.none && (stanza_.from == null || stanza_.from == '')) {
      switch (addFrom) {
        case StanzaFromType.full: {
          stanza_ = stanza_.copyWith(from: _connectionSettings.jid.withResource(_resource).toString());
        }
        break;
        case StanzaFromType.bare: {
          stanza_ = stanza_.copyWith(from: _connectionSettings.jid.toBare().toString());
        }
        break;
        case StanzaFromType.none: break;
      }
    }

    final stanzaString = stanza_.toXml();
    final id = stanza_.id!;

    _log.fine('Attempting to acquire lock for $id...');
    var future = Future.value(XMLNode(tag: 'not-used'));
    await _awaitingResponseLock.synchronized(() async {
        _log.fine('Lock acquired for $id');
        if (awaitable) {
          _awaitingResponse[id] = Completer();
        }

        _log.fine('Running pre stanza handlers..');
        await _runOutoingPreStanzaHandlers(stanza_, initial: StanzaHandlerData(false, stanza_, retransmitted: retransmitted));
        _log.fine('Done');

        // This uses the StreamManager to behave like a send queue
        final canSendData = _canSendData();
        if (canSendData) {
          _socket.write(stanzaString);

          // Try to ack every stanza
          // NOTE: Here we have send an Ack request nonza. This is now done by StreamManagementManager when receiving the StanzaSentEvent
        } else {
          _log.fine('_canSendData() returned false since _connectionState == $_connectionState');
        }

        _log.fine('Running post stanza handlers..');
        await _runOutoingPostStanzaHandlers(stanza_, initial: StanzaHandlerData(false, stanza_, retransmitted: retransmitted));
        _log.fine('Done');

        if (awaitable) {
          future = _awaitingResponse[id]!.future;
        }

        _log.fine('Releasing lock for $id');
    });

    return future;
  }

  /// Sets the connection state to [state] and triggers an event of type
  /// [ConnectionStateChangedEvent].
  void _setConnectionState(XmppConnectionState state) {
    _log.finest('Updating _connectionState from $_connectionState to $state');
    _connectionState = state;
    _eventStreamController.add(ConnectionStateChangedEvent(state: state, resumed: _resuming));

    if (state == XmppConnectionState.connected) {
      _log.finest('Starting _pingConnectionTimer');
      _connectionPingTimer = Timer.periodic(connectionPingDuration, _pingConnectionOpen);
    } else {
      if (_connectionPingTimer != null) {
        _log.finest('Destroying _pingConnectionTimer');
        _connectionPingTimer!.cancel();
        _connectionPingTimer = null;
      }
    }
  }
  
  /// Sets the routing state and logs the change
  void _updateRoutingState(RoutingState state) {
    _log.finest('Updating _routingState from $_routingState to $state');
    _routingState = state;
  }
  
  /// Returns the connection's events as a stream.
  Stream<XmppEvent> asBroadcastStream() {
    return _eventStreamController.stream.asBroadcastStream();
  }  
  
  /// Timer callback to prevent the connection from timing out.
  void _pingConnectionOpen(Timer timer) {
    // Follow the recommendation of XEP-0198 and just request an ack. If SM is not enabled,
    // send a whitespace ping
    _log.finest('_pingConnectionTimer: Callback called.');
    if (_connectionState == XmppConnectionState.connected) {
      _log.finest('_pingConnectionTimer: Connected. Triggering a ping event.');
      _sendEvent(SendPingEvent());
    } else {
      _log.finest('_pingConnectionTimer: Not connected. Not triggering an event.');
    }
  }

  /// Iterate over [handlers] and check if the handler matches [stanza]. If it does,
  /// call its callback and end the processing if the callback returned true; continue
  /// if it returned false.
  Future<bool> _runStanzaHandlers(List<StanzaHandler> handlers, Stanza stanza, { StanzaHandlerData? initial }) async {
    var state = initial ?? StanzaHandlerData(false, stanza);
    for (final handler in handlers) {
      if (handler.matches(state.stanza)) {
        state = await handler.callback(state.stanza, state);
        if (state.done) return true;
      }
    }

    return false;
  }

  Future<bool> _runIncomingStanzaHandlers(Stanza stanza) async {
    return _runStanzaHandlers(_incomingStanzaHandlers, stanza,);
  }

  Future<bool> _runOutoingPreStanzaHandlers(Stanza stanza, { StanzaHandlerData? initial }) async {
    return _runStanzaHandlers(_outgoingPreStanzaHandlers, stanza, initial: initial);
  }

  Future<bool> _runOutoingPostStanzaHandlers(Stanza stanza, { StanzaHandlerData? initial }) async {
    return _runStanzaHandlers(_outgoingPostStanzaHandlers, stanza, initial: initial);
  }
  
  /// Called whenever we receive a stanza after resource binding or stream resumption.
  Future<void> _handleStanza(XMLNode nonza) async {
    // Process nonzas separately
    if (!['message', 'iq', 'presence'].contains(nonza.tag)) {
      var nonzaHandled = false;
      await Future.forEach(
        _xmppManagers.values,
        (XmppManagerBase manager) async {
          final handled = await manager.runNonzaHandlers(nonza);

          if (!nonzaHandled && handled) nonzaHandled = true;
        }
      );

      if (!nonzaHandled) {
        _log.warning('Unhandled nonza received: ${nonza.toXml()}');
      }
      return;
    }

    // See if we are waiting for this stanza
    final stanza = Stanza.fromXMLNode(nonza);
    final id = stanza.attributes['id'] as String?;
    var awaited = false;
    await _awaitingResponseLock.synchronized(() async {
      if (id != null && _awaitingResponse.containsKey(id)) {
        _awaitingResponse[id]!.complete(stanza);
        _awaitingResponse.remove(id);
        awaited = true;
      }
    });
    if (awaited) {
      return;
    }

    // Run the incoming stanza handlers and bounce with an error if no manager handled
    // it.
    final stanzaHandled = await _runIncomingStanzaHandlers(stanza);
    if (!stanzaHandled) {
      handleUnhandledStanza(this, stanza);
    }
  }

  /// Returns true if all mandatory features in [features] have been negotiated.
  /// Otherwise returns false.
  bool _isMandatoryNegotiationDone(List<XMLNode> features) {
    return features.every(
      (XMLNode feature) {
        return feature.firstTag('required') == null && feature.tag != 'mechanisms';
      }
    );
  }

  /// Returns true if we can still negotiate. Returns false if no negotiator is
  /// matching and ready.
  bool _isNegotiationPossible(List<XMLNode> features) {
    return getNextNegotiator(features, log: false) != null;
  }

  /// Returns the next negotiator that matches [features]. Returns null if none can be
  /// picked. If [log] is true, then the list of matching negotiators will be logged.
  @visibleForTesting
  XmppFeatureNegotiatorBase? getNextNegotiator(List<XMLNode> features, {bool log = true}) {
    final matchingNegotiators = _featureNegotiators.values
      .where(
        (XmppFeatureNegotiatorBase negotiator) {
          return negotiator.state == NegotiatorState.ready && negotiator.matchesFeature(features);
        }
      )
      .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    if (log) {
      _log.finest('List of matching negotiators: ${matchingNegotiators.map((a) => a.id)}');
    }
    
    if (matchingNegotiators.isEmpty) return null;

    return matchingNegotiators.first;
  }

  Future<void> _performDiscoSweep() async {
    final disco = getDiscoManager();
    final discoCache = getDiscoCacheManager();
    final serverJid = _connectionSettings.jid.domain;
    final info = await discoCache.getInfoByJid(serverJid);
    if (info != null) {
      _log.finest('Discovered supported server features: ${info.features}');
      _serverFeatures.addAll(info.features);
      await _sendEvent(ServerDiscoDoneEvent());
    } else {
      _log.warning('Failed to discover server features');
    }

    final items = await disco.discoItemsQuery(serverJid);
    if (items != null) {
      _log.finest('Discovered disco items form $serverJid');

      // Query all items
      for (final item in items) {
        _log.finest('Querying info for ${item.jid}...');
        final itemInfo = await discoCache.getInfoByJid(item.jid);
        if (itemInfo != null) {
          _log.finest('Received info for ${item.jid}');
          await _sendEvent(ServerItemDiscoEvent(info: itemInfo, jid: item.jid));
        } else {
          _log.warning('Failed to discover info for ${item.jid}');
        }
      }
    } else {
      _log.warning('Failed to discover items of $serverJid');
    }
  }

  /// Called once all negotiations are done. Sends the initial presence and performs
  /// a disco sweep.
  Future<void> _onNegotiationsDone() async {
    await getPresenceManager().sendInitialPresence();

    if (_serverFeatures.isEmpty) {
      await _performDiscoSweep();
    } else {
      _log.info('Not performing disco sweep as _serverFeatures is not empty');
    }
  }
  
  /// To be called after _currentNegotiator!.negotiate(..) has been called. Checks the
  /// state of the negotiator and picks the next negotiatior, ends negotiation or
  /// waits, depending on what the negotiator did.
  Future<void> _checkCurrentNegotiator() async {
    if (_currentNegotiator!.state == NegotiatorState.done) {
      _log.finest('Negotiator ${_currentNegotiator!.id} done');

      if (_currentNegotiator!.sendStreamHeaderWhenDone) {
        _currentNegotiator = null;
        _streamFeatures.clear();
        _sendStreamHeader();
      } else {
        // Track what features we still have
        _streamFeatures
          .removeWhere((node) {
            return node.attributes['xmlns'] == _currentNegotiator!.negotiatingXmlns;
          });
        _currentNegotiator = null;

        if (_isMandatoryNegotiationDone(_streamFeatures) && !_isNegotiationPossible(_streamFeatures)) {
          _log.finest('Negotiations done!');
          _updateRoutingState(RoutingState.handleStanzas);

          await _onNegotiationsDone();
        } else {
          _currentNegotiator = getNextNegotiator(_streamFeatures);
          _log.finest('Chose ${_currentNegotiator!.id} as next negotiator');

          final fakeStanza = XMLNode(
            tag: 'stream:features',
            children: _streamFeatures,
          );
          await _currentNegotiator!.negotiate(fakeStanza);
          await _checkCurrentNegotiator();
        }
      }
    } else if (_currentNegotiator!.state == NegotiatorState.retryLater) {
      _log.finest('Negotiator want to continue later. Picking new one...');

      _currentNegotiator!.state = NegotiatorState.ready;

      if (_isMandatoryNegotiationDone(_streamFeatures) && !_isNegotiationPossible(_streamFeatures)) {
        _log.finest('Negotiations done!');

        _updateRoutingState(RoutingState.handleStanzas);
        await _onNegotiationsDone();
      } else {
        _log.finest('Picking new negotiator...');
        _currentNegotiator = getNextNegotiator(_streamFeatures);
        _log.finest('Chose $_currentNegotiator as next negotiator');
        final fakeStanza = XMLNode(
          tag: 'stream:features',
          children: _streamFeatures,
        );
        await _currentNegotiator!.negotiate(fakeStanza);
        await _checkCurrentNegotiator();
      }
    }
  }
  
  /// Called whenever we receive data that has been parsed as XML.
  Future<void> handleXmlStream(XMLNode node) async {
    switch (_routingState) {
      case RoutingState.negotiating:
        if (_currentNegotiator != null) {
          // If we already have a negotiator, just let it do its thing
          _log.finest('Negotiator currently active...');

          await _currentNegotiator!.negotiate(node);
          await _checkCurrentNegotiator();
        } else {
          _streamFeatures
            ..clear()
            ..addAll(node.children);

          // We need to pick a new one
          if (_isMandatoryNegotiationDone(node.children)) {
            // Mandatory features are done but can we still negotiate more?
            if (_isNegotiationPossible(node.children)) {// We can still negotiate features, so do that.
              _log.finest('All required stream features done! Continuing negotiation');
              _currentNegotiator = getNextNegotiator(node.children);
              _log.finest('Chose $_currentNegotiator as next negotiator');
              await _currentNegotiator!.negotiate(node);
              await _checkCurrentNegotiator();
            } else {
              _updateRoutingState(RoutingState.handleStanzas);
            }
          } else {
            // There still are mandatory features
            if (!_isNegotiationPossible(node.children)) {
              _log.severe('Mandatory negotiations not done but continuation not possible');
              _updateRoutingState(RoutingState.error);
              return;
            }

            _currentNegotiator = getNextNegotiator(node.children);
            _log.finest('Chose $_currentNegotiator as next negotiator');
            await _currentNegotiator!.negotiate(node);
            await _checkCurrentNegotiator();
          }
        }
        break;
      case RoutingState.handleStanzas:
        await _handleStanza(node);
        break;
      case RoutingState.preConnection:
      case RoutingState.error:
        _log.warning('Received data while in non-receiving state');
        break;
    }
  }
  
  /// Sends an event to the connection's event stream.
  Future<void> _sendEvent(XmppEvent event) async {
    _log.finest('Event: ${event.toString()}');

    // Specific event handling
    if (event is AckRequestResponseTimeoutEvent) {
      _reconnectionPolicy.onFailure();
    } else if (event is ResourceBindingSuccessEvent) {
      _log.finest('Received ResourceBindingSuccessEvent. Setting _resource to ${event.resource}');
      _resource = event.resource;

      _log.finest('Resetting _serverFeatures');
      _serverFeatures.clear();
    }
    
    for (final manager in _xmppManagers.values) {
      await manager.onXmppEvent(event);
    }

    _eventStreamController.add(event);
  }

  /// Sends a stream header to the socket.
  void _sendStreamHeader() {
    _socket.write(
      XMLNode(
        tag: 'xml',
        attributes: <String, String>{
          'version': '1.0'
        },
        closeTag: false,
        isDeclaration: true,
        children: [
          StreamHeaderNonza(_connectionSettings.jid.domain),
        ],
      ).toXml(),
    );
  }

  /// To be called when we lost the network connection.
  void _onNetworkConnectionLost() {
    _socket.close();
    _setConnectionState(XmppConnectionState.notConnected);
  }

  /// Attempt to gracefully close the session
  Future<void> disconnect() async {
    _reconnectionPolicy.setShouldReconnect(false);
    _disconnecting = true;
    getPresenceManager().sendUnavailablePresence();
    sendRawString('</stream:stream>');
    _setConnectionState(XmppConnectionState.notConnected);
    _socket.close();

    // Clear Stream Management state, if available
    await getStreamManagementManager()?.resetState();
  }

  /// Make sure that all required managers are registered
  void _runPreConnectionAssertions() {
    assert(_xmppManagers.containsKey(presenceManager), 'A PresenceManager is mandatory');
    assert(_xmppManagers.containsKey(rosterManager), 'A RosterManager is mandatory');
    assert(_xmppManagers.containsKey(discoManager), 'A DiscoManager is mandatory');
    assert(_xmppManagers.containsKey(pingManager), 'A PingManager is mandatory');
  }
  
  /// Like [connect] but the Future resolves when the resource binding is either done or
  /// SASL has failed.
  Future<XmppConnectionResult> connectAwaitable({ String? lastResource }) {
    _runPreConnectionAssertions();
    _connectionCompleter = Completer();
    connect(lastResource: lastResource);
    return _connectionCompleter!.future;
  }
 
  /// Start the connection process using the provided connection settings.
  Future<void> connect({ String? lastResource }) async {
    _runPreConnectionAssertions();
    _reconnectionPolicy.setShouldReconnect(true);
    _disconnecting = false;
    
    if (lastResource != null) {
      _resource = lastResource;
    }

    _reconnectionPolicy.reset();

    _resuming = true;
    await _sendEvent(ConnectingEvent());

    final smManager = getStreamManagementManager();
    String? host;
    int? port;
    if (smManager?.state.streamResumptionLocation != null) {
      // TODO(Unknown): Maybe wrap this in a try catch?
      final parsed = Uri.parse(smManager!.state.streamResumptionLocation!);
      host = parsed.host;
      port = parsed.port;
    }
    
    final result = await _socket.connect(
      _connectionSettings.jid.domain,
      host: host,
      port: port,
    );
    if (!result) {
      handleError(null);
    } else {
      _reconnectionPolicy.onSuccess();
      _log.fine('Preparing the internal state for a connection attempt');
      _performingStartTLS = false;
      _resetNegotiators();
      _setConnectionState(XmppConnectionState.connecting);
      _updateRoutingState(RoutingState.negotiating);
      _sendStreamHeader();
    }
  }
}
