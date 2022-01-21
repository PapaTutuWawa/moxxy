import "dart:async";

// TODO: Replace this with one that is better
import "package:basic_utils/basic_utils.dart";

class XEP0368LookupResult {
  final String hostname;
  final int port;

  XEP0368LookupResult({ required this.hostname, required this.port });
}

Future<XEP0368LookupResult?> perform0368Lookup(String domain) async {
  // TODO: WHY CAN'T WE JUST USE THE SYSTEM RESOLVER?
  final records = await DnsUtils.lookupRecord(
    "_xmpps-client._tcp." + domain,
    RRecordType.SRV,
    provider: DnsApiProvider.CLOUDFLARE
  );

  if (records == null) return null;
  if (records.isEmpty) return null;

  // TODO: We are ignoring the priority
  final dataParts = records[0].data.split(" ");
  return XEP0368LookupResult(
    hostname: dataParts[3],
    port: int.parse(dataParts[2])
  );
}
