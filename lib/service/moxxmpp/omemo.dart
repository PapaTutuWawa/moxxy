import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/omemo.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384.dart';
import 'package:omemo_dart/omemo_dart.dart';

class MoxxyOmemoManager extends OmemoManager {

  MoxxyOmemoManager(OmemoSessionManager omemoState) : super(omemoState);

  // TODO(PapaTutuWawa): Override the storage related methods
  @override
  Future<void> commitRatchet(OmemoDoubleRatchet ratchet, String jid, int deviceId) async {
    await GetIt.I.get<DatabaseService>().saveRatchet(
      OmemoDoubleRatchetWrapper(ratchet, deviceId, jid),
    );
  }
}
