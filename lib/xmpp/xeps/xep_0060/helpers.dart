import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/errors.dart';

PubSubError getPubSubError(XMLNode stanza) {
  final error = stanza.firstTag('error');
  if (error != null) {
    final conflict = error.firstTag('conflict');
    final preconditions = error.firstTag('precondition-not-met');

    if (conflict != null && preconditions != null) return PreconditionsNotMetError();
  }
  
  return UnknownPubSubError();
}
