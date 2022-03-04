import "dart:convert";

import "package:moxxyv2/xmpp/rfcs/rfc_4790.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";

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

  if (info.extendedInfo.isNotEmpty) {
    final sortedExt = info.extendedInfo..sort((a, b) => ioctetSortComparator(
        a.getFieldByVar("FORM_TYPE")!.values.first,
        b.getFieldByVar("FORM_TYPE")!.values.first
      )
    );

    for (final ext in sortedExt) {
      s += ext.getFieldByVar("FORM_TYPE")!.values.first + "<";

      final sortedFields = ext.fields..sort((a, b) => ioctetSortComparator(
          a.varAttr!,
          b.varAttr!
        )
      );

      for (final field in sortedFields) {
        if (field.varAttr == "FORM_TYPE") continue;

        s += field.varAttr! + "<";
        final sortedValues = field.values..sort(ioctetSortComparator);
        for (final value in sortedValues) {
          s += value + "<";
        }
      }
    }
  }
  
  return base64.encode((await algorithm.hash(utf8.encode(s))).bytes);
}
