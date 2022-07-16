import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";
import "package:moxxyv2/xmpp/negotiators/namespaces.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

class CSIActiveNonza extends XMLNode {
  CSIActiveNonza() : super(
    tag: "active",
    attributes: {
      "xmlns": csiXmlns
    }
  );
}

class CSIInactiveNonza extends XMLNode {
  CSIInactiveNonza() : super(
    tag: "inactive",
    attributes: {
      "xmlns": csiXmlns
    }
  );
}

/// A Stub negotiator that is just for "intercepting" the stream feature.
class CSINegotiator extends XmppFeatureNegotiatorBase {
  CSINegotiator() : _supported = false, super(0, false, csiNegotiator, csiXmlns);

  /// True if CSI is supported. False otherwise.
  bool _supported;
  bool get isSupported => _supported;
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
    // negotiate is only called when the negotiator matched, meaning the server
    // advertises CSI.
    _supported = true;
    state = NegotiatorState.done;
  }

  @override
  void reset() {
    _supported = false;

    super.reset();
  }
}

/// The manager requires a CSINegotiator to be registered as a feature negotiator.
class CSIManager extends XmppManagerBase {
  bool _isActive;

  CSIManager() : _isActive = true, super(); 

  @override
  String getId() => csiManager;

  @override
  String getName() => "CSIManager";

  bool _supported() {
    return (getAttributes().getNegotiatorById(csiNegotiator)! as CSINegotiator).isSupported;
  }
  
  /// To be called after a stream has been resumed as CSI does not
  /// survive a stream resumption.
  void restoreCSIState() {
    if (_isActive) {
      setActive();
    } else {
      setInactive();
    }
  }
  
  /// Tells the server to top optimizing traffic
  void setActive() {
    _isActive = true;

    final attrs = getAttributes();
    if (_supported()) {
      attrs.sendNonza(CSIActiveNonza());
    }
  }

  /// Tells the server to optimize traffic following XEP-0352
  void setInactive() {
    _isActive = false;

    final attrs = getAttributes();
    if (_supported()) {
      attrs.sendNonza(CSIInactiveNonza());
    }
  }
}
