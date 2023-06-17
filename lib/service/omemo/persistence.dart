import 'package:omemo_dart/omemo_dart.dart';

Future<void> commitDevice(OmemoDevice device) async {
  // TODO
}

Future<OmemoDevice?> loadOmemoDevice(String jid) async {
  // TODO
  return null;
}

Future<void> commitRatchets(List<OmemoRatchetData> ratchets) async {
  // TODO
}

Future<void> commitDeviceList(String jid, List<int> added, List<int> removed,) async {
  // TODO
}

Future<void> removeRatchets(List<RatchetMapKey> ratchets) async {
  // TODO
}

Future<OmemoDataPackage?> loadRatchets(String jid) async {
  // TODO
  return null;
}

Future<void> commitTrust(BTBVTrustData trust) async {
  // TODO
}

Future<List<BTBVTrustData>> loadTrust(String jid) async {
  // TODO
  return [];
}

Future<void> removeTrust(String jid) async {
  // TODO
}
