import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";

import "package:xml/xml.dart";
import "package:xml/xml_events.dart";

class XmlStreamBuffer extends StreamTransformerBase<String, XMLNode> {
  String _buffer;
  final StreamController<XMLNode> _streamController;
  final XmlNodeDecoder _decoder;

  XmlStreamBuffer()
    : _buffer = "",
      _streamController = StreamController(),
      _decoder = XmlNodeDecoder();

  @override
  Stream<XMLNode> bind(Stream<String> stream) {
    stream.toXmlEvents().selectSubtreeEvents((event) {
        if (event is XmlStartElementEvent) {
          return event.qualifiedName != "stream:stream";
        } else if (event is XmlEndElementEvent) {
          return event.qualifiedName != "stream:stream";
        }

        return true;
    }).transform(_decoder).listen((nodes) {

        print(nodes);
        for (final node in nodes) {
          if (node.nodeType == XmlNodeType.ELEMENT) {
            _streamController.add(XMLNode.fromXmlElement(node as XmlElement));
          }
        }
    });
    return _streamController.stream;
  }
}
