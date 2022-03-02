import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

XMLNode makeMessageDeliveryRequest() {
  return XMLNode.xmlns(
    tag: "request",
    xmlns: deliveryXmlns
  );
}

XMLNode makeMessageDeliveryResponse(String id) {
  return XMLNode.xmlns(
    tag: "received",
    xmlns: deliveryXmlns,
    attributes: { "id": id }
  );
}
