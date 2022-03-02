import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

XMLNode makeChatMarkerMarkable() {
  return XMLNode.xmlns(
    tag: "markable",
    xmlns: chatMarkersXmlns
  );
}
