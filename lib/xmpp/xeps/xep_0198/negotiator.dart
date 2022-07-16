import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/state.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/nonzas.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";
import "package:logging/logging.dart";

enum _StreamManagementNegotiatorState {
  // We have not done anything yet
  ready,
  // The SM resume has been requested
  resumeRequested,
  // The SM enablement has been requested
  enableRequested,
}

class StreamManagementNegotiator extends XmppFeatureNegotiatorBase {
  _StreamManagementNegotiatorState _state;

  final Logger _log;

  StreamManagementNegotiator()
    : _state = _StreamManagementNegotiatorState.ready,
      _log = Logger("StreamManagementNegotiator"),
      super(10, false, smXmlns, streamManagementNegotiator);

  @override
  bool matchesFeature(List<XMLNode> features) {
    switch (_state) {
      case _StreamManagementNegotiatorState.ready:
        // We have not done anything, so try to resume
        return firstWhereOrNull(
          features,
          (XMLNode feature) => feature.attributes["xmlns"] == smXmlns
        ) != null;
      case _StreamManagementNegotiatorState.resumeRequested:
        // Resume failed, so try to enable once we have bound a resource
        final bindResourceNegotiator = attributes.getNegotiatorById(resourceBindingNegotiator);
        return bindResourceNegotiator?.state == NegotiatorState.done;
      default:
        return false;
    }
  }
      
  @override
  Future<void> negotiate(XMLNode nonza) async {
    switch (_state) {
      case _StreamManagementNegotiatorState.ready:
        final sm = attributes.getManagerById(smManager)! as StreamManagementManager;

        await sm.loadState();
        final srid = sm.state.streamResumptionId;
        final h = sm.state.s2c;

        // Attempt stream resumption first
        if (srid != null) {
          _log.finest("Found stream resumption Id. Attempting to perform stream resumption");
          _state = _StreamManagementNegotiatorState.resumeRequested;
          attributes.sendNonza(StreamManagementResumeNonza(srid, h));
        } else {
          _log.finest("Attempting to enable stream management");
          _state = _StreamManagementNegotiatorState.enableRequested;
          attributes.sendNonza(StreamManagementEnableNonza());
        }
        break;
        case _StreamManagementNegotiatorState.resumeRequested:
          if (nonza.tag == "resumed") {
            _log.finest("Stream Management resumption successful");

            assert(attributes.getFullJID().resource != "");

            final csi = attributes.getManagerById(csiManager) as CSIManager?;
            if (csi != null) {
              csi.restoreCSIState();
            }

            final h = int.parse(nonza.attributes["h"]!);
            await attributes.sendEvent(StreamResumedEvent(h: h));

            state = NegotiatorState.done;
          } else {
            // We assume it is <failed />
            _log.info("Stream resumption failed. Proceeding with new stream...");
            final sm = attributes.getManagerById(smManager)! as StreamManagementManager;

            // We have to do this because we otherwise get a stanza stuck in the queue,
            // thus spamming the server on every <a /> nonza we receive.
            sm.setState(StreamManagementState(0, 0));
            await sm.commitState();

            state = NegotiatorState.retryLater;
          }
        break;
      case _StreamManagementNegotiatorState.enableRequested:
        if (nonza.tag == "enabled") {
          _log.finest("Stream Management enabled");

          final id = nonza.attributes["id"];
          if (id != null && ["true", "1"].contains(nonza.attributes["resume"])) {
            _log.info("Stream Resumption available");
          }

          attributes.sendEvent(
            StreamManagementEnabledEvent(
              resource: attributes.getFullJID().resource,
              id: id,
              location: nonza.attributes["location"],
            ),
          );

          state = NegotiatorState.done;
        } else {
          // We assume a <failed />
          _log.warning("Stream Management enablement failed");
          state = NegotiatorState.done;
        }

        break;
    }
  }

  @override
  void reset() {
    _state = _StreamManagementNegotiatorState.ready;

    super.reset();
  }
}
