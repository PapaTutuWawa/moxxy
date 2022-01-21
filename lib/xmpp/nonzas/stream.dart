import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class StreamHeaderNonza extends XMLNode {
  StreamHeaderNonza(String serverDomain) : super(
      tag: "stream:stream",
      attributes: {
        "xmlns": stanzaXmlns,
        "version": "1.0",
        "xmlns:stream": streamXmlns,
        "to": serverDomain,
        "xml:lang": "en"
      },
      closeTag: false
    );
}
