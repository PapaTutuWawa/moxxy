import "dart:async";

import "package:moxxyv2/xmpp/address.dart";
import "package:moxxyv2/xmpp/rfcs/rfc_2782.dart";

import "package:moxdns/moxdns.dart";


Future<List<XmppConnectionAddress>> perform0368Lookup(String domain) async {
  // TODO: Maybe enable DNSSEC one day
  final results = await Moxdns.srvQuery("_xmpps-client._tcp.$domain", false);
  if (results.isEmpty) {
    return const [];
  }

  results.sort(srvRecordSortComparator);
  return results.map((result) => XmppConnectionAddress(
      hostname: result.target,
      port: result.port
  )).toList();
}
