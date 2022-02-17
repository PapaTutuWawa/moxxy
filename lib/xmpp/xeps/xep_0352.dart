import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

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

class CSIManager extends XmppManagerBase {
  bool _isActive;

  CSIManager() : _isActive = true, super(); 

  @override
  String getId() => csiManager;

  @override
  String getName() => "CSIManager";
  
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
    if (attrs.isStreamFeatureSupported(csiXmlns)) {
      attrs.sendNonza(CSIActiveNonza());
    }
  }

  /// Tells the server to optimize traffic following XEP-0352
  void setInactive() {
    _isActive = false;

    final attrs = getAttributes();
    if (attrs.isStreamFeatureSupported(csiXmlns)) {
      attrs.sendNonza(CSIInactiveNonza());
    }
  }
}
