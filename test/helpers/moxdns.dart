import "dart:async";

import "package:moxdns/moxdns.dart";

Future<List<SrvRecord>> srvQueryStub(String domain, bool dnssec) async {
  return const [
    SrvRecord(
      target: "some.server",
      port: 5223,
      priority: 0,
      weight: 0
    )
  ];
}
