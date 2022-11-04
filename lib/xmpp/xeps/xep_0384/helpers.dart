import 'dart:math';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:omemo_dart/omemo_dart.dart';
import 'package:random_string/random_string.dart';

/// Generate a random alpha-numeric string with a random length between 0 and 200 in
/// accordance to XEP-0420's rpad affix element.
String generateRpad() {
  final random = Random.secure();
  final length = random.nextInt(200);
  return randomAlphaNumeric(length, provider: CoreRandomProvider.from(random));
}

/// Convert the XML representation of an OMEMO bundle into an OmemoBundle object.
/// [jid] refers to the JID the bundle belongs to. [id] refers to the bundle's device
/// identifier. [bundle] refers to the <bundle /> element.
///
/// Returns the OmemoBundle.
OmemoBundle bundleFromXML(JID jid, int id, XMLNode bundle) {
  assert(bundle.attributes['xmlns'] == omemoXmlns, 'Invalid xmlns');

  final spk = bundle.firstTag('spk')!;
  final prekeys = <int, String>{};
  for (final pk in bundle.firstTag('prekeys')!.findTags('pk')) {
    prekeys[int.parse(pk.attributes['id']! as String)] = pk.innerText();
  }

  return OmemoBundle(
    jid.toBare().toString(),
    id,
    spk.innerText(),
    int.parse(spk.attributes['id']! as String),
    bundle.firstTag('spks')!.innerText(),
    bundle.firstTag('ik')!.innerText(),
    prekeys,
  );
}

/// Converts an OmemoBundle [bundle] into its XML representation.
///
/// Returns the XML element.
XMLNode bundleToXML(OmemoBundle bundle) {
  final prekeys = List<XMLNode>.empty(growable: true);
  for (final pk in bundle.opksEncoded.entries) {
    prekeys.add(
      XMLNode(
        tag: 'pk', attributes: <String, String>{
          'id': '${pk.key}',
        },
        text: pk.value,
      ),
    );
  }

  return XMLNode.xmlns(
    tag: 'bundle',
    xmlns: omemoXmlns,
    children: [
      XMLNode(
        tag: 'spk',
        attributes: <String, String>{
          'id': '${bundle.spkId}',
        },
        text: bundle.spkEncoded,
      ),
      XMLNode(
        tag: 'spks',
        text: bundle.spkSignatureEncoded,
      ),
      XMLNode(
        tag: 'ik',
        text: bundle.ikEncoded,
      ),
      XMLNode(
        tag: 'prekeys',
        children: prekeys,
      ),
    ],
  );
}
