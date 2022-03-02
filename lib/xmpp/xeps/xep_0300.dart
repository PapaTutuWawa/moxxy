import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

XMLNode constructHashElement(String algo, String base64Hash) {
  return XMLNode.xmlns(
    tag: "hash",
    xmlns: hashXmlns,
    attributes: { "algo": algo },
    text: base64Hash
  );
}
