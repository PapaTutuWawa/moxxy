import "dart:convert";

import "package:moxxyv2/xmpp/rfcs/rfc_4790.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030.dart";

import "package:cryptography/cryptography.dart";

/// Calculates the Entitiy Capability hash according to XEP-0115 based on the
/// disco information.
Future<String> calculateCapabilityHash(DiscoInfo info, HashAlgorithm algorithm) async {
  String s = "";
  final List<String> identitiesSorted = info.identities.toList().map((i) => i.category + "/" + i.type + "/" + (i.lang ?? "") + "/" + i.name).toList();
  identitiesSorted.sort(ioctetSortComparator);
  s += identitiesSorted.join("<") + "<";

  List<String> featuresSorted = List.from(info.features);
  featuresSorted.sort(ioctetSortComparator);
  s += featuresSorted.join("<") + "<";

  if (info.extendedInfo != null) {
    s += info.extendedInfo!["FORM_TYPE"]![0] + "<";
    final sortedVars = info.extendedInfo!.keys.where((k) => k != "FORM_TYPE").toList()..sort(ioctetSortComparator);

    for (var key in sortedVars) {
      s += key + "<";

      final sortedValues = info.extendedInfo![key]!.toList();
      sortedValues.sort(ioctetSortComparator);

      s += sortedValues.join("<") + "<";
    }
  }
  
  return base64.encode((await algorithm.hash(utf8.encode(s))).bytes);
}
