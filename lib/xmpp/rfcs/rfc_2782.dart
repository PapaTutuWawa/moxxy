import "package:moxdns/moxdns.dart";

/// Sorts the SRV records according to priority and weight.
int srvRecordSortComparator(SrvRecord a, SrvRecord b) {
  if (a.priority < b.priority) {
    return -1;
  } else {
    if (a.priority > b.priority) {
      return 1;
    }

    // a.priority == b.priority
    if (a.weight < b.weight) {
      return -1;
    } else if (a.weight > b.weight) {
      return 1;
    } else {
      return 0;
    }
  }
}
