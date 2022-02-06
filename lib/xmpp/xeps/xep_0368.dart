import "dart:async";

import "package:moxxyv2/xmpp/address.dart";
import "package:moxxyv2/xmpp/rfcs/rfc_2782.dart";

import "package:moxdns/moxdns.dart";

typedef SrvQueryFunction = Future<List<SrvRecord>> Function(String, bool);

Future<List<XmppConnectionAddress>> perform0368Lookup(String domain, { SrvQueryFunction? srvQuery }) async {
  final query = srvQuery ?? Moxdns.srvQuery;
  // TODO: Maybe enable DNSSEC one day
  final results = await query("_xmpps-client._tcp.$domain", false);
  if (results.isEmpty) {
    return const [];
  }

  results.sort(srvRecordSortComparator);
  return results.map((result) => XmppConnectionAddress(
      hostname: result.target,
      port: result.port
  )).toList();
}
