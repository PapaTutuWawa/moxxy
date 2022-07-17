import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class SaslAuthNonza extends XMLNode {
  SaslAuthNonza(String mechanism, String body) : super(
    tag: "auth",
    attributes: {
      "xmlns": saslXmlns,
      "mechanism": mechanism 
    },
    text: body
  );
}
