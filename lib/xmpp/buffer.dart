import 'dart:async';

import 'package:moxxyv2/xmpp/stringxml.dart';

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

class XmlStreamBuffer extends StreamTransformerBase<String, XMLNode> {

  XmlStreamBuffer() : _streamController = StreamController(), _decoder = const XmlNodeDecoder();
  final StreamController<XMLNode> _streamController;
  final XmlNodeDecoder _decoder;

  @override
  Stream<XMLNode> bind(Stream<String> stream) {
    stream.toXmlEvents().selectSubtreeEvents((event) {
      return event.qualifiedName != 'stream:stream';
    }).transform(_decoder).listen((nodes) {
      for (final node in nodes) {
        if (node.nodeType == XmlNodeType.ELEMENT) {
          _streamController.add(XMLNode.fromXmlElement(node as XmlElement));
        }
      }
    });
    return _streamController.stream;
  }
}
