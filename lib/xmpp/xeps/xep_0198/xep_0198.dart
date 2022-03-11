import "dart:async";

import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/state.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/nonzas.dart";

const xmlUintMax = 4294967296; // 2**32

class _UnackedStanza {
  final Stanza stanza;
  final int timestamp;

  const _UnackedStanza(this.stanza, this.timestamp);
}

class StreamManagementManager extends XmppManagerBase {
  /// Commitable state of the StreamManagementManager
  StreamManagementState _state;
  
  final Map<int, _UnackedStanza> _unackedStanzas;
  bool _streamManagementEnabled;
  Timer? _ackTimer;
  final Duration ackDuration;
  final bool enableTimer;

  /// Creates an XmppManager that implements XEP-0198.
  /// [ackDuration] is the time which is given the server to ack every stanza. If
  /// a stanza is older than [ackDuration], it will be resent.
  /// [enableTimer] is an option that is only used for testing. It will disable the
  /// timer.
  StreamManagementManager({
      this.ackDuration = const Duration(seconds: 10),
      this.enableTimer = true
  }) :
  _state = StreamManagementState(0, 0),
    _unackedStanzas = {},
    _streamManagementEnabled = false;
    
  /// Functions for testing
  Map<int, _UnackedStanza> getUnackedStanzas() => _unackedStanzas;

  /// Called whenever the timer elapses. If [timer] is null, then the function
  /// will log that is has been called outside of the timer.
  /// [ignoreTimestamp] will ignore the timestamps and mercylessly retransmit every
  /// stanza in the queue. Usefull for testing and stream resumption.
  void onTimerElapsed(Timer? timer, { bool ignoreTimestamps = false }) {
    if (timer != null) {
      logger.finest("SM Timer elapsed");
    } else {
      logger.finest("onTimerElapsed called outside of the timer");
    }

    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final attrs = getAttributes();
    bool hasRetransmittedStanza = false;
    for (final i in _unackedStanzas.keys) {
      final item = _unackedStanzas[i]!;
      if (ignoreTimestamps || currentTimestamp - item.timestamp > ackDuration.inMilliseconds) {
        logger.finest("Retransmitting stanza");
        attrs.sendStanza(item.stanza);
        _unackedStanzas[i] = _UnackedStanza(
          item.stanza,
          currentTimestamp
        );
        hasRetransmittedStanza = true;
      }
    }

    if (hasRetransmittedStanza) {
      _sendAckRequestPing();
    }
  }

  void _stopTimer() {
    if (_ackTimer != null) {
      logger.finest("Stopping SM timer");
      _ackTimer!.cancel();
      _ackTimer = null;
    }
  }

  void _startTimer() {
    if (_ackTimer == null && enableTimer) {
      logger.finest("Starting SM timer");
      _ackTimer = Timer.periodic(ackDuration, onTimerElapsed);
    }
  }
  
  /// May be overwritten by a subclass. Should save [state] so that it can be loaded again
  /// with [this.loadState].
  Future<void> commitState() async {}
  Future<void> loadState() async {}

  void setState(StreamManagementState state) {
    _state = state;
  }
  StreamManagementState get state => _state;
  
  @override
  String getId() => smManager;

  @override
  String getName() => "StreamManagementManager";

  @override
  List<NonzaHandler> getNonzaHandlers() => [
    NonzaHandler(
      nonzaTag: "r",
      nonzaXmlns: smXmlns,
      callback: _handleAckRequest
    ),
    NonzaHandler(
      nonzaTag: "a",
      nonzaXmlns: smXmlns,
      callback: _handleAckResponse
    )
  ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      callback: _onServerStanzaReceived
    )
  ];

  @override
  List<StanzaHandler> getOutgoingStanzaHandlers() => [
    StanzaHandler(
      callback: _onClientStanzaSent
    )
  ];
  
  @override
  void onXmppEvent(XmppEvent event) {
    if (event is SendPingEvent) {
      if (isStreamManagementEnabled()) {
        _sendAckRequestPing();
      } else {
        getAttributes().sendRawXml("");
      }
    } else if (event is StreamResumedEvent) {
      _enableStreamManagement();
      _onStreamResumed(event.h);
    } else if (event is StreamManagementEnabledEvent) {
      _enableStreamManagement();

      setState(StreamManagementState(
          0,
          0,
          streamResumptionId: event.id,
          streamResumptionLocation: event.location
      ));
      commitState();
    } else if (event is ConnectingEvent) {
      _disableStreamManagement();
    }
  }

  /// Resets the enablement of stream management, but __NOT__ the internal state.
  /// This is to prevent ack requests being sent before we resume or re-enable
  /// stream management.
  void _disableStreamManagement() {
    _streamManagementEnabled = false;
  }
  
  /// Enables support for XEP-0198 stream management
  void _enableStreamManagement() {
    _streamManagementEnabled = true;
  }
  
  /// Returns whether XEP-0198 stream management is enabled
  bool isStreamManagementEnabled() => _streamManagementEnabled;

  /// To be called when receiving a <a /> nonza.
  Future<bool> _handleAckRequest(XMLNode nonza) async {
    final attrs = getAttributes();
    logger.finest("Sending ack response");
    attrs.sendNonza(StreamManagementAckNonza(_state.s2c));

    return true;
  }

  /// Called when we receive an <a /> nonza from the server.
  /// This is a response to the question "How many of my stanzas have you handled".
  Future<bool> _handleAckResponse(XMLNode nonza) async {
    final h = int.parse(nonza.attributes["h"]!);
    
    _removeHandledStanzas(h);
    _state = _state.copyWith(c2s: h);
    await commitState();

    if (_unackedStanzas.isEmpty) {
      _stopTimer();
    }

    return true;
  }

  // Just a helper function to not increment the counters above xmlUintMax
  void _incrementC2S() {
    final c2s = _state.c2s;
    if (c2s + 1 == xmlUintMax) {
      _state = _state.copyWith(c2s: 0);
    } else {
      _state = _state.copyWith(c2s: c2s + 1);
    }

    commitState();
  }
  void _incrementS2C() {
    final s2c = _state.s2c;
    if (s2c + 1 == xmlUintMax) {
      _state = _state.copyWith(s2c: 0);
    } else {
      _state = _state.copyWith(s2c: s2c + 1);
    }

    commitState();
  }
  
  /// Called whenever we receive a stanza from the server.
  Future<StanzaHandlerData> _onServerStanzaReceived(Stanza stanza, StanzaHandlerData state) async {
    _incrementS2C();
    return state;
  }

  /// Called whenever we send a stanza.
  Future<StanzaHandlerData> _onClientStanzaSent(Stanza stanza, StanzaHandlerData state) async {
    _startTimer();

    _incrementC2S();
    _unackedStanzas[_state.c2s] = _UnackedStanza(stanza, DateTime.now().millisecondsSinceEpoch);

    logger.fine("Queue after sending: " + _unackedStanzas.toString());

    if (isStreamManagementEnabled()) {
      getAttributes().sendNonza(StreamManagementRequestNonza());
    }

    return state;
  }

  /// Removes all stanzas in the unacked queue that have a sequence number less-than or
  /// equal to [h].
  void _removeHandledStanzas(int h) {
    // NOTE: Dart does not allow for a cleaner way that does both in the same iteration
    // TODO: But what if... :flushed:
    final attrs = getAttributes();
    _unackedStanzas.forEach(
      (key, value) {
        if (key <= h && value.stanza.tag == "message" && value.stanza.id != null) {
          attrs.sendEvent(MessageAckedEvent(id: value.stanza.id!));
        }
      }
    );
    
    _unackedStanzas.removeWhere(
      (key, _) => key <= h
    );
    logger.fine("Queue after cleaning: " + _unackedStanzas.toString());


  }

  /// To be called when the stream has been resumed
  void _onStreamResumed(int h) {
    _state = _state.copyWith(s2c: h);
    commitState();

    _removeHandledStanzas(h);
    onTimerElapsed(null, ignoreTimestamps: true);
  }

  /// Pings the connection open by send an ack request
  void _sendAckRequestPing() {
    getAttributes().sendNonza(StreamManagementRequestNonza());
  }
}
