import 'dart:async';

import 'package:moxdns/moxdns.dart';

Future<List<SrvRecord>> srvQueryStub(String domain, bool dnssec) async {
  return [
    const SrvRecord('some.server', 5223, 0, 0)
  ];
}
