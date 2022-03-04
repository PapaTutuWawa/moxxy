import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

XMLNode makeChatMarkerMarkable() {
  return XMLNode.xmlns(
    tag: "markable",
    xmlns: chatMarkersXmlns
  );
}

XMLNode makeChatMarker(String tag, String id) {
  assert(["received", "displayed", "acknowledged"].contains(tag));
  return XMLNode.xmlns(
    tag: tag,
    xmlns: chatMarkersXmlns,
    attributes: { "id": id }
  );
}
