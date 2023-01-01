import 'package:omemo_dart/omemo_dart.dart';

Future<OmemoDevice> generateNewIdentityImpl(String jid) async {
  return OmemoDevice.generateNewDevice(jid);
}
