import 'package:moxdns/moxdns.dart';
import 'package:moxxmpp_socket_tcp/moxxmpp_socket_tcp.dart';

class MoxxyTCPSocketWrapper extends TCPSocketWrapper {
  MoxxyTCPSocketWrapper() : super();

  @override
  Future<List<MoxSrvRecord>> srvQuery(String domain, bool dnssec) async {
    final records = await MoxdnsPlugin.srvQuery(domain, dnssec);
    return records
        .map(
          (record) => MoxSrvRecord(
            record.priority,
            record.weight,
            record.target,
            record.port,
          ),
        )
        .toList();
  }
}
