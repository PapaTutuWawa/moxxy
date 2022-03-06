import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

const xmlUintMax = 4294967296; // 2**32

class StreamManagementEnableNonza extends XMLNode {
  StreamManagementEnableNonza() : super(
    tag: "enable",
    attributes: {
      "xmlns": smXmlns,
      "resume": "true"
    }
  );
}

class StreamManagementResumeNonza extends XMLNode {
  StreamManagementResumeNonza(String id, int h) : super(
    tag: "resume",
    attributes: {
      "xmlns": smXmlns,
      "previd": id,
      "h": h.toString()
    }
  );
}

class StreamManagementAckNonza extends XMLNode {
  StreamManagementAckNonza(int h) : super(
    tag: "a",
    attributes: {
      "xmlns": smXmlns,
      "h": h.toString()
    }
  );
}

class StreamManagementRequestNonza extends XMLNode {
  StreamManagementRequestNonza() : super(
    tag: "r",
    attributes: {
      "xmlns": smXmlns,
    }
  );
}

class _UnackedStanza {
  final Stanza stanza;
  final int timestamp;

  const _UnackedStanza(this.stanza, this.timestamp);
}

class StreamManagementManager extends XmppManagerBase {
  // Amount of stanzas we have sent or handled
  int _c2sStanzaCount;
  int _s2cStanzaCount;
  final Map<int, _UnackedStanza> _unackedStanzas;
  String? _streamResumptionId;
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
    _s2cStanzaCount = 0,
    _c2sStanzaCount = 0,
    _unackedStanzas = {},
    _streamResumptionId = null,
    _streamManagementEnabled = false;
    
  /// Functions for testing
  int getC2SStanzaCount() => _c2sStanzaCount;
  int getS2CStanzaCount() => _s2cStanzaCount;
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
  
  /// May be overwritten by a subclass. Should save [_c2sStanzaCount] and [_s2cStanzaCount]
  /// so that they can be loaded again with [this.loadState].
  Future<void> commitState() async {}
  Future<void> loadState() async {}

  void setState(int? c2s, int? s2c) {
    // Prevent this being called multiple times
    //assert(_c2sStanzaCount == 0);
    //assert(_s2cStanzaCount == 0);

    _c2sStanzaCount = c2s ?? _c2sStanzaCount;
    _s2cStanzaCount = s2c ?? _c2sStanzaCount;
  }

  /// May be overwritten by a subclass. Should save and load [_streamResumptionId].
  Future<void> commitStreamResumptionId() async {}
  Future<void> loadStreamResumptionId() async {}

  void setStreamResumptionId(String id) {
    // Prevent this being called multiple times
    //assert(_streamResumptionId == null);

    _streamResumptionId = id;
  }

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
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      callback: _serverStanzaReceived
    )
  ];

  @override
  void onXmppEvent(XmppEvent event) {
    if (event is StanzaSentEvent) {
      _onClientStanzaSent(event.stanza);
    } else if (event is SendPingEvent) {
      if (isStreamManagementEnabled()) {
        _sendAckRequestPing();
      } else {
        getAttributes().sendRawXml("");
      }
    } else if (event is StreamResumedEvent) {
      _enableStreamManagement();
      _onStreamResumed(event.h);
    } else if (event is StreamManagementEnabledEvent) {
      _streamResumptionId = event.id;
      commitStreamResumptionId();
      _enableStreamManagement();

      setState(0, 0);
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
    attrs.sendNonza(StreamManagementAckNonza(_s2cStanzaCount));

    return true;
  }

  /// Called when we receive an <a /> nonza from the server.
  /// This is a response to the question "How many of my stanzas have you handled".
  Future<bool> _handleAckResponse(XMLNode nonza) async {
    final h = int.parse(nonza.attributes["h"]!);
    
    _removeHandledStanzas(h);
    _c2sStanzaCount = h;

    if (_unackedStanzas.isEmpty) {
      _stopTimer();
    }

    return true;
  }

  // Just a helper function to not increment the counters above xmlUintMax
  void _incrementC2S() {
     if (_c2sStanzaCount + 1 == xmlUintMax) {
      _c2sStanzaCount = 0;
    } else {
      _c2sStanzaCount++;
    }

    commitState();
  }
  void _incrementS2C() {
    if (_s2cStanzaCount + 1 == xmlUintMax) {
      _s2cStanzaCount = 0;
    } else {
      _s2cStanzaCount++;
    }

    commitState();
  }
  
  /// Called whenever we receive a stanza from the server.
  Future<bool> _serverStanzaReceived(stanza) async {
    _incrementS2C();
    return false;
  }

  /// Called whenever we send a stanza.
  void _onClientStanzaSent(Stanza stanza) {
    _startTimer();

    _incrementC2S();
    _unackedStanzas[_c2sStanzaCount] = _UnackedStanza(stanza, DateTime.now().millisecondsSinceEpoch);

    logger.fine("Queue after sending: " + _unackedStanzas.toString());

    if (isStreamManagementEnabled()) {
      getAttributes().sendNonza(StreamManagementRequestNonza());
    }
  }

  /// Removes all stanzas in the unacked queue that have a sequence number less-than or
  /// equal to [h].
  void _removeHandledStanzas(int h) {
    _unackedStanzas.removeWhere(
      (key, _) => key <= h
    );
    logger.fine("Queue after cleaning: " + _unackedStanzas.toString());
  }

  /// To be called when the stream has been resumed
  void _onStreamResumed(int h) {
    _s2cStanzaCount = h;

    commitState();

    _removeHandledStanzas(h);
    onTimerElapsed(null, ignoreTimestamps: true);
  }

  /// Pings the connection open by send an ack request
  void _sendAckRequestPing() {
    getAttributes().sendNonza(StreamManagementRequestNonza());
  }

  /// Returns the stream resumption id we have
  String? getStreamResumptionId() {
    return _streamResumptionId;
  }
}
