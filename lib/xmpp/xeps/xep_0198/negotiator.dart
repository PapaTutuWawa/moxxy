import 'package:logging/logging.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/nonzas.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/state.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0352.dart';

enum _StreamManagementNegotiatorState {
  // We have not done anything yet
  ready,
  // The SM resume has been requested
  resumeRequested,
  // The SM enablement has been requested
  enableRequested,
}

/// NOTE: The stream management negotiator requires that loadState has been called on the
///       StreamManagementManager at least once before connecting, if stream resumption
///       is wanted.
class StreamManagementNegotiator extends XmppFeatureNegotiatorBase {
  
  StreamManagementNegotiator()
    : _state = _StreamManagementNegotiatorState.ready,
      _supported = false,
      _resumeFailed = false,
      _isResumed = false,
      _log = Logger('StreamManagementNegotiator'),
      super(10, false, smXmlns, streamManagementNegotiator);
  _StreamManagementNegotiatorState _state;
  bool _resumeFailed;
  bool _isResumed;
 
  final Logger _log;

  /// True if Stream Management is supported on this stream.
  bool _supported;
  bool get isSupported => _supported;

  /// True if the current stream is resumed. False if not.
  bool get isResumed => _isResumed;
  
  @override
  bool matchesFeature(List<XMLNode> features) {
    final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;

    if (sm.state.streamResumptionId != null && !_resumeFailed) {
      // We could do Stream resumption
      return super.matchesFeature(features) && attributes.isAuthenticated();
    } else {
      // We cannot do a stream resumption
      final br = attributes.getNegotiatorById(resourceBindingNegotiator);
      return super.matchesFeature(features) && br?.state == NegotiatorState.done && attributes.isAuthenticated();
    }
  }
      
  @override
  Future<void> negotiate(XMLNode nonza) async {
    // negotiate is only called when we matched the stream feature, so we know
    // that the server advertises it.
    _supported = true;

    switch (_state) {
      case _StreamManagementNegotiatorState.ready:
        final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;
        final srid = sm.state.streamResumptionId;
        final h = sm.state.s2c;

        // Attempt stream resumption first
        if (srid != null) {
          _log.finest('Found stream resumption Id. Attempting to perform stream resumption');
          _state = _StreamManagementNegotiatorState.resumeRequested;
          attributes.sendNonza(StreamManagementResumeNonza(srid, h));
        } else {
          _log.finest('Attempting to enable stream management');
          _state = _StreamManagementNegotiatorState.enableRequested;
          attributes.sendNonza(StreamManagementEnableNonza());
        }
        break;
        case _StreamManagementNegotiatorState.resumeRequested:
          if (nonza.tag == 'resumed') {
            _log.finest('Stream Management resumption successful');

            assert(attributes.getFullJID().resource != '', 'Resume only works when we already have a resource bound and know about it');

            final csi = attributes.getManagerById(csiManager) as CSIManager?;
            if (csi != null) {
              csi.restoreCSIState();
            }

            final h = int.parse(nonza.attributes['h']! as String);
            await attributes.sendEvent(StreamResumedEvent(h: h));

            _resumeFailed = false;
            _isResumed = true;
            state = NegotiatorState.skipRest;
          } else {
            // We assume it is <failed />
            _log.info('Stream resumption failed. Expected <resumed />, got ${nonza.tag}, Proceeding with new stream...');
            await attributes.sendEvent(StreamResumeFailedEvent());
            final sm = attributes.getManagerById<StreamManagementManager>(smManager)!;

            // We have to do this because we otherwise get a stanza stuck in the queue,
            // thus spamming the server on every <a /> nonza we receive.
            // ignore: cascade_invocations
            await sm.setState(StreamManagementState(0, 0));
            await sm.commitState();

            _resumeFailed = true;
            _isResumed = false;
            _state = _StreamManagementNegotiatorState.ready;
            state = NegotiatorState.retryLater;
          }
        break;
      case _StreamManagementNegotiatorState.enableRequested:
        if (nonza.tag == 'enabled') {
          _log.finest('Stream Management enabled');

          final id = nonza.attributes['id'] as String?;
          if (id != null && ['true', '1'].contains(nonza.attributes['resume'])) {
            _log.info('Stream Resumption available');
          }

          await attributes.sendEvent(
            StreamManagementEnabledEvent(
              resource: attributes.getFullJID().resource,
              id: id,
              location: nonza.attributes['location'] as String?,
            ),
          );

          state = NegotiatorState.done;
        } else {
          // We assume a <failed />
          _log.warning('Stream Management enablement failed');
          state = NegotiatorState.done;
        }

        break;
    }
  }

  @override
  void reset() {
    _state = _StreamManagementNegotiatorState.ready;
    _supported = false;
    _resumeFailed = false;
    _isResumed = false;

    super.reset();
  }
}
