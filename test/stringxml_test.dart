import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'helpers/xml.dart';

void main() {
  test('Test stringxml', () {
    final child = XMLNode(tag: 'uwu', attributes: { 'strength': 10 });
    final stanza = XMLNode.xmlns(tag: 'uwu-meter', xmlns: 'uwu', children: [ child ]);
    expect(XMLNode(tag: 'iq', attributes: {'xmlns': 'uwu'}).toXml(), "<iq xmlns='uwu' />");
    expect(XMLNode.xmlns(tag: 'iq', xmlns: 'uwu', attributes: {'how': 'uwu'}).toXml(), "<iq xmlns='uwu' how='uwu' />");
    expect(stanza.toXml(), "<uwu-meter xmlns='uwu'><uwu strength=10 /></uwu-meter>");

    expect(StreamHeaderNonza('uwu.server').toXml(), "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='uwu.server' xml:lang='en'>");

    expect(XMLNode(tag: 'text', attributes: {}, text: 'hallo').toXml(), '<text>hallo</text>');
    expect(XMLNode(tag: 'text', attributes: { 'world': 'no' }, text: 'hallo').toXml(), "<text world='no'>hallo</text>");
    expect(XMLNode(tag: 'text', attributes: {}, text: 'hallo').toXml(), '<text>hallo</text>');
    expect(XMLNode(tag: 'text', attributes: {}, text: 'test').innerText(), 'test');
  });

  test('Test XmlElement', () {
    expect(XMLNode.fromXmlElement(XmlDocument.parse("<root owo='uwu' />").firstElementChild!).toXml(), "<root owo='uwu' />");
  });

  test('Test the find functions', () {
    final node1 = XMLNode.fromString('<message><a xmlns="a" /><body>Hallo</body></message>');

    expect(compareXMLNodes(node1.firstTag('body')!, XMLNode.fromString('<body>Hallo</body>')), true);
    expect(compareXMLNodes(node1.firstTagByXmlns('a')!, XMLNode.fromString('<a xmlns="a" />')), true);
  });
}
