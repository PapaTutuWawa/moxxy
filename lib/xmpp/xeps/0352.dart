import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class CSIActiveNonza extends XMLNode {
  CSIActiveNonza() : super(
    tag: "active",
    attributes: {
      "xmlns": CSI_XMLNS
    }
  );
}

class CSIInactiveNonza extends XMLNode {
  CSIInactiveNonza() : super(
    tag: "inactive",
    attributes: {
      "xmlns": CSI_XMLNS
    }
  );
}

// TODO: Remember the CSI state in case we resume a stream
class CSIManager extends XmppManagerBase {
  @override
  String getId() => CSI_MANAGER;

  /// Tells the server to top optimizing traffic
  void setActive() {
    final attrs = getAttributes();
    if (attrs.isStreamFeatureSupported(CSI_XMLNS)) {
      attrs.sendNonza(CSIActiveNonza());
    }
  }

  /// Tells the server to optimize traffic following XEP-0352
  void setInactive() {
    final attrs = getAttributes();
    if (attrs.isStreamFeatureSupported(CSI_XMLNS)) {
      attrs.sendNonza(CSIInactiveNonza());
    }
  }
}
