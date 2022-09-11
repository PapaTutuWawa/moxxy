import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

/// Checks the OMEMO affix elements. [envelope] refers to the  <envelope /> element we get
/// after decrypting the payload. [sender] refers to the "to" attribute of the stanza.
/// [ourJid] is our current full Jid.
///
/// Returns true if the affix elements are all valid and as expected. Returns false if not.
bool checkAffixElements(XMLNode envelope, String sender, JID ourJid) {
  final from = envelope.firstTag('from')?.attributes['jid'] as String?;
  if (from == null) return false;
  final encSender = JID.fromString(from);

  final to = envelope.firstTag('to')?.attributes['jid'] as String?;
  if (to == null) return false;
  final encReceiver = JID.fromString(to);

  return encSender.toBare().toString() == JID.fromString(sender).toBare().toString() &&
    encReceiver.toBare().toString() == ourJid.toBare().toString();
}
