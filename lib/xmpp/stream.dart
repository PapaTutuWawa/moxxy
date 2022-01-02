import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";

import "package:xml/xml.dart";

class XmlStreamBuffer extends StreamTransformerBase<String, XMLNode> {
  String _buffer;
  final StreamController<XMLNode> _streamController;

  XmlStreamBuffer() : _buffer = "", _streamController = StreamController();

  void _listener(String data) {
    String toParse = this._buffer + data;
    if (toParse.startsWith("<?xml version='1.0'?>")) {
      toParse = toParse.substring(21);
    }

    if (toParse.startsWith("<stream:stream")) {
      toParse = toParse + "</stream:stream>";
    } else {
      if (toParse.endsWith("</stream:stream>")) {
        // TODO: Maybe destroy the stream
        toParse = toParse.substring(0, toParse.length - 16);
      }
    } 

    final document;
    try {
      document = XmlDocument.parse("<root>$toParse</root>");
      this._buffer = "";
    } catch (ex) {
      // TODO: Maybe don't just assume that we haven't received everything, i.e. check the
      //       error message
      this._buffer = this._buffer + data;
      return;
    }

    document.getElement("root")!
      .childElements
      .forEach((element) => this._streamController.add(XMLNode.fromXmlElement(element)));
  }
  
  Stream<XMLNode> bind(Stream<String> stream) {
    stream.listen(this._listener);
    return this._streamController.stream;
  }
}
