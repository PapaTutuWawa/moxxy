import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060/errors.dart';

PubSubError getPubSubError(XMLNode stanza) {
  final error = stanza.firstTag('error');
  if (error != null) {
    final conflict = error.firstTag('conflict');
    final preconditions = error.firstTag('precondition-not-met');
    if (conflict != null && preconditions != null) {
      return PreconditionsNotMetError();
    }

    final badRequest = error.firstTag('bad-request', xmlns: fullStanzaXmlns);
    final text = error.firstTag('text', xmlns: fullStanzaXmlns);
    if (error.attributes['type'] == 'modify' &&
        badRequest != null &&
        text != null &&
        (text.text ?? '').contains('max_items')) {
      return EjabberdMaxItemsError();
    }
  }
  
  return UnknownPubSubError();
}
