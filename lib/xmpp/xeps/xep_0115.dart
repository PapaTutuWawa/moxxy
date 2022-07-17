import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:moxxyv2/xmpp/rfcs/rfc_4790.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart';

/// Calculates the Entitiy Capability hash according to XEP-0115 based on the
/// disco information.
Future<String> calculateCapabilityHash(DiscoInfo info, HashAlgorithm algorithm) async {
  final buffer = StringBuffer();
  final identitiesSorted = info.identities
    .map((Identity i) => '${i.category}/${i.type}/${i.lang ?? ""}/${i.name ?? ""}')
    .toList();
  // ignore: cascade_invocations
  identitiesSorted.sort(ioctetSortComparator);
  buffer.write('${identitiesSorted.join("<")}<');

  final featuresSorted = List<String>.from(info.features)
    ..sort(ioctetSortComparator);
  buffer.write('${featuresSorted.join("<")}<');

  if (info.extendedInfo.isNotEmpty) {
    final sortedExt = info.extendedInfo
      ..sort((a, b) => ioctetSortComparator(
        a.getFieldByVar('FORM_TYPE')!.values.first,
        b.getFieldByVar('FORM_TYPE')!.values.first,
      ),
    );

    for (final ext in sortedExt) {
      buffer.write('${ext.getFieldByVar("FORM_TYPE")!.values.first}<');

      final sortedFields = ext.fields..sort((a, b) => ioctetSortComparator(
          a.varAttr!,
          b.varAttr!,
        ),
      );

      for (final field in sortedFields) {
        if (field.varAttr == 'FORM_TYPE') continue;

        buffer.write('${field.varAttr!}<');
        final sortedValues = field.values..sort(ioctetSortComparator);
        for (final value in sortedValues) {
          buffer.write('$value<');
        }
      }
    }
  }
  
  return base64.encode((await algorithm.hash(utf8.encode(buffer.toString()))).bytes);
}
