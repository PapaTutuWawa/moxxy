import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

/// Extracts the message stanza from the <forwarded /> node.
Stanza unpackForwarded(XMLNode forwarded) {
  assert(forwarded.attributes['xmlns'] == forwardedXmlns, 'Invalid element xmlns');
  assert(forwarded.tag == 'forwarded', 'Invalid element name');

  // NOTE: We only use this XEP (for now) in the context of Message Carbons
  final stanza = forwarded.firstTag('message', xmlns: stanzaXmlns)!;
  return Stanza(
    to: stanza.attributes['to']! as String,
    from: stanza.attributes['from']! as String,
    type: stanza.attributes['type']! as String,
    id: stanza.attributes['id']! as String,
    tag: stanza.tag,
    attributes: stanza.attributes as Map<String, String>,
    children: stanza.children,
  );
}
