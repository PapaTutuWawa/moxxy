import "dart:collection";

/// Sorts [toSort] using the i;octet collation defined by RFC 4790
/// TODO: Maybe enforce utf8?
int ioctetSortComparator(String a, String b) {
  if (a.isEmpty && b.isEmpty) {
    return 0;
  }

  if (a.isEmpty && b.isNotEmpty) {
    return -1;
  }

  if (a.isNotEmpty && b.isEmpty) {
    return 1;
  }

  if (a[0] == b[0]) {
    return ioctetSortComparator(a.substring(1), b.substring(1));
  }

  // TODO: Is this correct?
  if (a.codeUnitAt(0) < b.codeUnitAt(0)) {
    return -1;
  }
  
  return 1;
}
