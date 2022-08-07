import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/negotiator.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/nonzas.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/state.dart';
import 'package:synchronized/synchronized.dart';

const xmlUintMax = 4294967296; // 2**32

class StreamManagementManager extends XmppManagerBase {

  StreamManagementManager({
      this.ackTimeout = const Duration(seconds: 30),
  })
  : _state = StreamManagementState(0, 0),
    _unackedStanzas = {},
    _stateLock = Lock(),
    _streamManagementEnabled = false,
    _lastAckTimestamp = -1,
    _pendingAcks = 0,
    _streamResumed = false,
    _ackLock = Lock();
  /// The queue of stanzas that are not (yet) acked
  final Map<int, Stanza> _unackedStanzas;
  /// Commitable state of the StreamManagementManager
  StreamManagementState _state;
  /// Mutex lock for _state
  final Lock _stateLock;
  /// If the have enabled SM on the stream yet
  bool _streamManagementEnabled;
  /// If the current stream has been resumed;
  bool _streamResumed;
  /// The time in which the response to an ack is still valid. Counts as a timeout
  /// otherwise
  @internal
  final Duration ackTimeout;
  /// The time at which the last ack has been sent
  int _lastAckTimestamp;
  /// The timer to see if we timed the connection out
  Timer? _ackTimer;
  /// Counts how many acks we're waiting for
  int _pendingAcks;
  /// Lock for both [_lastAckTimestamp] and [_pendingAcks].
  final Lock _ackLock;

  /// Functions for testing
  @visibleForTesting
  Map<int, Stanza> getUnackedStanzas() => _unackedStanzas;

  @visibleForTesting
  Future<int> getPendingAcks() async {
    var acks = 0;

    await _ackLock.synchronized(() async {
      acks = _pendingAcks;
    });

    return acks;
  }

  @override
  Future<bool> isSupported() async {
    return getAttributes().getNegotiatorById<StreamManagementNegotiator>(streamManagementNegotiator)!.isSupported;
  }
  
  /// Returns the amount of stanzas waiting to get acked
  int getUnackedStanzaCount() => _unackedStanzas.length;

  /// May be overwritten by a subclass. Should save [state] so that it can be loaded again
  /// with [this.loadState].
  Future<void> commitState() async {}
  Future<void> loadState() async {}

  void setState(StreamManagementState state) {
    _state = state;
  }

  /// Resets the state such that a resumption is no longer possible without creating
  /// a new session. Primarily useful for clearing the state after disconnecting
  Future<void> resetState() async {
    await _stateLock.synchronized(() async {
        setState(_state.copyWith(
            c2s: 0,
            s2c: 0,
            streamResumptionLocation: null,
            streamResumptionId: null,
        ),);
        await commitState();
    });
  }
  
  StreamManagementState get state => _state;

  bool get streamResumed => _streamResumed;
  
  @override
  String getId() => smManager;

  @override
  String getName() => 'StreamManagementManager';

  @override
  List<NonzaHandler> getNonzaHandlers() => [
    NonzaHandler(
      nonzaTag: 'r',
      nonzaXmlns: smXmlns,
      callback: _handleAckRequest,
    ),
    NonzaHandler(
      nonzaTag: 'a',
      nonzaXmlns: smXmlns,
      callback: _handleAckResponse,
    )
  ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      callback: _onServerStanzaReceived,
    )
  ];

  @override
  List<StanzaHandler> getOutgoingPostStanzaHandlers() => [
    StanzaHandler(
      callback: _onClientStanzaSent,
    )
  ];
  
  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is StreamResumedEvent) {
      _enableStreamManagement();

      await _ackLock.synchronized(() async {
          _pendingAcks = 0;
      });

      await onStreamResumed(event.h);
    } else if (event is StreamManagementEnabledEvent) {
      _enableStreamManagement();

      await _ackLock.synchronized(() async {
          _pendingAcks = 0;
      });

      await _stateLock.synchronized(() async {
          setState(StreamManagementState(
              0,
              0,
              streamResumptionId: event.id,
              streamResumptionLocation: event.location,
          ),);
          await commitState();
      });
    } else if (event is ConnectingEvent) {
      _disableStreamManagement();
      _streamResumed = false;
    }
  }

  /// Starts the timer to detect timeouts based on ack responses, if the timer
  /// is not already running.
  void _startAckTimer() {
    if (_ackTimer != null) return;

    logger.fine('Starting ack timer');
    _ackTimer = Timer.periodic(
      ackTimeout,
      _ackTimerCallback,
    );
  }

  /// Stops the timer, if it is running.
  void _stopAckTimer() {
    if (_ackTimer == null) return;

    logger.fine('Stopping ack timer');
    _ackTimer!.cancel();
    _ackTimer = null;
  }

  /// Timer callback that checks if all acks have been answered. If not and the last
  /// response has been more that [ackTimeout] in the past, declare the session dead.
  void _ackTimerCallback(Timer timer) {
    _ackLock.synchronized(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - _lastAckTimestamp >= ackTimeout.inMilliseconds && _pendingAcks > 0) {
        _stopAckTimer();
        await getAttributes().getConnection().reconnectionPolicy.onFailure();
      }
    });
  }

  /// Wrapper around sending an <r /> nonza that starts the ack timeout timer.
  Future<void> _sendAckRequest() async {
    logger.fine('_sendAckRequest: Waiting to acquire lock...');
    await _ackLock.synchronized(() async {
      logger.fine('_sendAckRequest: Done...');
      final now = DateTime.now().millisecondsSinceEpoch;

      _lastAckTimestamp = now;
      _pendingAcks++;
      _startAckTimer();

      logger.fine('_pendingAcks is now at $_pendingAcks');
      
      getAttributes().sendNonza(StreamManagementRequestNonza());
      
      logger.fine('_sendAckRequest: Releasing lock...');
    }); 
  }
  
  /// Resets the enablement of stream management, but __NOT__ the internal state.
  /// This is to prevent ack requests being sent before we resume or re-enable
  /// stream management.
  void _disableStreamManagement() {
    _streamManagementEnabled = false;
    logger.finest('Stream Management disabled');
  }
  
  /// Enables support for XEP-0198 stream management
  void _enableStreamManagement() {
    _streamManagementEnabled = true;
    logger.finest('Stream Management enabled');
  }
  
  /// Returns whether XEP-0198 stream management is enabled
  bool isStreamManagementEnabled() => _streamManagementEnabled;

  /// To be called when receiving a <a /> nonza.
  Future<bool> _handleAckRequest(XMLNode nonza) async {
    final attrs = getAttributes();
    logger.finest('Sending ack response');
    await _stateLock.synchronized(() async {
        attrs.sendNonza(StreamManagementAckNonza(_state.s2c));
    });

    return true;
  }

  /// Called when we receive an <a /> nonza from the server.
  /// This is a response to the question "How many of my stanzas have you handled".
  Future<bool> _handleAckResponse(XMLNode nonza) async {
    final h = int.parse(nonza.attributes['h']! as String);

    await _ackLock.synchronized(() async {
      await _stateLock.synchronized(() async {
        if (_pendingAcks > 0) {
          // Prevent diff from becoming negative
          final diff = max(_state.c2s - h, 0);
          _pendingAcks = diff;
        } else {
          _stopAckTimer();
        }

        logger.fine('_pendingAcks is now at $_pendingAcks');
      });
    });
    
    // Return early if we acked nothing.
    // Taken from slixmpp's stream management code
    logger.fine('_handleAckResponse: Waiting to aquire lock...');
    await _stateLock.synchronized(() async {
        logger.fine('_handleAckResponse: Done...');
        if (h == _state.c2s && _unackedStanzas.isEmpty) {
          logger.fine('_handleAckResponse: Releasing lock...');
          return;
        }

        final attrs = getAttributes();
        final sequences = _unackedStanzas.keys.toList()..sort();
        for (final height in sequences) {
          // Do nothing if the ack does not concern this stanza
          if (height > h) continue;

          final stanza = _unackedStanzas[height]!;
          _unackedStanzas.remove(height);
          if (stanza.tag == 'message' && stanza.id != null) {
            attrs.sendEvent(
              MessageAckedEvent(
                id: stanza.id!,
                to: stanza.to!,
              ),
            );
          }
        }

        if (h > _state.c2s) {
          logger.info('C2S height jumped from ${_state.c2s} (local) to $h (remote).');
          // ignore: cascade_invocations
          logger.info('Proceeding with $h as local C2S counter.');

          _state = _state.copyWith(c2s: h);
          await commitState();
        }

        logger.fine('_handleAckResponse: Releasing lock...');
    });

    return true;
  }

  // Just a helper function to not increment the counters above xmlUintMax
  Future<void> _incrementC2S() async {
    logger.fine('_incrementC2S: Waiting to aquire lock...');
    await _stateLock.synchronized(() async {
        logger.fine('_incrementC2S: Done');
        _state = _state.copyWith(c2s: _state.c2s + 1 % xmlUintMax);
        await commitState();
        logger.fine('_incrementC2S: Releasing lock...');
    });
  }
  Future<void> _incrementS2C() async {
    logger.fine('_incrementS2C: Waiting to aquire lock...');
    await _stateLock.synchronized(() async {
        logger.fine('_incrementS2C: Done');
        _state = _state.copyWith(s2c: _state.s2c + 1 % xmlUintMax);
        await commitState();
        logger.fine('_incrementS2C: Releasing lock...');
    });
  }
  
  /// Called whenever we receive a stanza from the server.
  Future<StanzaHandlerData> _onServerStanzaReceived(Stanza stanza, StanzaHandlerData state) async {
    await _incrementS2C();
    return state;
  }

  /// Called whenever we send a stanza.
  Future<StanzaHandlerData> _onClientStanzaSent(Stanza stanza, StanzaHandlerData state) async {
    await _incrementC2S();
    _unackedStanzas[_state.c2s] = stanza;
    
    if (isStreamManagementEnabled() && !state.retransmitted) {
      //logger.finest("Sending ack request");
      await _sendAckRequest();
    }

    return state;
  }

  /// To be called when the stream has been resumed
  @visibleForTesting
  Future<void> onStreamResumed(int h) async {
    _streamResumed = true;
    await _handleAckResponse(StreamManagementAckNonza(h));

    final stanzas = _unackedStanzas.values.toList();
    _unackedStanzas.clear();
    
    // Retransmit the rest of the queue
    final attrs = getAttributes();
    for (final stanza in stanzas) {
      await attrs.sendStanza(stanza, awaitable: false, retransmitted: true);
    }
    sendAckRequestPing();
  }

  /// Pings the connection open by send an ack request
  void sendAckRequestPing() {
    _sendAckRequest();
  }
}
