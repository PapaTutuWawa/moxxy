import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class StreamHeaderNonza extends XMLNode {
  StreamHeaderNonza(String serverDomain) : super(
      tag: "stream:stream",
      attributes: {
        "xmlns": STANZA_XMLNS,
        "version": "1.0",
        "xmlns:stream": STREAM_XMLNS,
        "to": serverDomain,
        "xml:lang": "en"
      },
      closeTag: false
    );
}
