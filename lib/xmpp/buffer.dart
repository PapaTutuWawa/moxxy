import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";

import "package:xml/xml.dart";

class XmlStreamBuffer extends StreamTransformerBase<String, XMLNode> {
  String _buffer;
  final StreamController<XMLNode> _streamController;

  XmlStreamBuffer() : _buffer = "", _streamController = StreamController();

  void _listener(String data) {
    String toParse = _buffer + data;
    if (toParse.startsWith("<?xml version='1.0'?>")) {
      toParse = toParse.substring(21);
    }

    if (toParse.startsWith("<stream:stream")) {
      toParse = toParse + "</stream:stream>";
    } else {
      if (toParse.endsWith("</stream:stream>")) {
        toParse = toParse.substring(0, toParse.length - 16);
        // In order for this class to have as little logic as possible, replace the
        // </stream:stream> with a <stream:stream /> such that we can parse it without
        // issue and catch it in [XmppConnection].
        toParse += "<stream:stream />";
      }
    } 

    final XmlDocument document;
    try {
      document = XmlDocument.parse("<root>$toParse</root>");
      _buffer = "";
    } catch (ex) {
      // TODO: Maybe don't just assume that we haven't received everything, i.e. check the
      //       error message
      _buffer = _buffer + data;
      return;
    }

    for (var element in document.getElement("root")!.childElements) {
      _streamController.add(XMLNode.fromXmlElement(element));
    }
  }

  @override
  Stream<XMLNode> bind(Stream<String> stream) {
    stream.listen(_listener);
    return _streamController.stream;
  }
}
