import "package:moxxyv2/xmpp/rfcs/rfc_2782.dart";

import "package:moxdns/moxdns.dart";
import "package:test/test.dart";

void main() {
  test("Test SRV ordering", () {
      final records = [
        const SrvRecord(
          target: "host2.server.example",
          port: 5222,
          priority: 2,
          weight: 3
        ),
        const SrvRecord(
          target: "host3.server.example",
          port: 5222,
          priority: 5,
          weight: 0
        ),
        const SrvRecord(
          target: "host4.server.example",
          port: 5222,
          priority: 2,
          weight: 1
        ),
        const SrvRecord(
          target: "host1.server.example",
          port: 5222,
          priority: 0,
          weight: 0
        )
      ];
      records.sort(srvRecordSortComparator);

      expect(records[0].target, "host1.server.example");
      expect(records[1].target, "host4.server.example");
      expect(records[2].target, "host2.server.example");
      expect(records[3].target, "host3.server.example");
  });
}
