import "dart:convert";

import "package:moxxyv2/xmpp/rfc/4790.dart";
import "package:moxxyv2/xmpp/xeps/0030.dart";

import "package:cryptography/cryptography.dart";

Future<String> calculateCapabilityHash(DiscoInfo info) async {
  String s = "";
  final identitiesSorted = info.identities.map((i) => i.category + "/" + i.type + "/" + (i.lang ?? "") + "/" + i.name).toList();
  identitiesSorted.sort(ioctetSortComparator);
  s += identitiesSorted.join("<") + "<";

  List<String> featuresSorted = info.features.toList();
  featuresSorted.sort(ioctetSortComparator);
  s += featuresSorted.join("<") + "<";

  if (info.extendedInfo != null) {
    s += info.extendedInfo!["FORM_TYPE"]![0] + "<";
    final sortedVars = info.extendedInfo!.keys.where((k) => k != "FORM_TYPE").toList()..sort(ioctetSortComparator);

    for (var key in sortedVars) {
      s += key + "<";

      final sortedValues = info.extendedInfo![key]!;
      sortedValues.sort(ioctetSortComparator);

      s += sortedValues.join("<") + "<";
    }
  }
  
  return base64.encode((await Sha1().hash(utf8.encode(s))).bytes);
}
