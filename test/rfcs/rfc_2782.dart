import 'package:moxdns/moxdns.dart';
import 'package:moxxyv2/xmpp/rfcs/rfc_2782.dart';
import 'package:test/test.dart';

void main() {
  test('Test SRV ordering', () {
      final records = [
        const SrvRecord('host2.server.example', 5222, 2, 3),
        const SrvRecord('host3.server.example', 5222, 5, 0),
        const SrvRecord('host4.server.example', 5222, 2, 1),
        const SrvRecord('host1.server.example', 5222, 0, 0)
      ];
      records.sort(srvRecordSortComparator);

      expect(records[0].target, 'host1.server.example');
      expect(records[1].target, 'host4.server.example');
      expect(records[2].target, 'host2.server.example');
      expect(records[3].target, 'host3.server.example');
  });
}
