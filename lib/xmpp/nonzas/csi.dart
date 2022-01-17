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
