import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/omemo/implementations.dart';
import 'package:moxxyv2/service/omemo/persistence.dart';
import 'package:moxxyv2/service/omemo/types.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart' as model;
import 'package:omemo_dart/omemo_dart.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:synchronized/synchronized.dart';

class OmemoDoubleRatchetWrapper {
  OmemoDoubleRatchetWrapper(this.ratchet, this.id, this.jid);
  final OmemoDoubleRatchet ratchet;
  final int id;
  final String jid;
}

class OmemoService {
  final Logger _log = Logger('OmemoService');

  bool _initialized = false;
  final Lock _lock = Lock();
  final Queue<Completer<void>> _waitingForInitialization =
      Queue<Completer<void>>();

  /// The manager to use for OMEMO.
  late OmemoManager _omemoManager;

  Future<OmemoManager> getOmemoManager() async {
    await ensureInitialized();
    return _omemoManager;
  }

  /// Ensures that the code following this *AWAITED* call can access every method
  /// of the OmemoService.
  Future<void> ensureInitialized() async {
    final completer = await _lock.synchronized(() {
      if (!_initialized) {
        final c = Completer<void>();
        _waitingForInitialization.add(c);
        return c;
      }

      return null;
    });

    if (completer != null) {
      await completer.future;
    }
  }

  Future<void> initializeIfNeeded(String jid) async {
    final done = await _lock.synchronized(() => _initialized);
    if (done) return;

    final device = await loadOmemoDevice(jid);
    if (device == null) {
      _log.info('No OMEMO marker found. Generating OMEMO identity...');
    } else {
      _log.info('OMEMO marker found. Restoring OMEMO state...');
    }

    final om = GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.OmemoManager>(moxxmpp.omemoManager)!;

    _omemoManager = OmemoManager(
      device ?? await compute(generateNewIdentityImpl, jid),
      BlindTrustBeforeVerificationTrustManager(
        commit: commitTrust,
        loadData: loadTrust,
        removeTrust: removeTrust,
      ),
      om.sendEmptyMessageImpl,
      om.fetchDeviceList,
      om.fetchDeviceBundle,
      om.subscribeToDeviceListImpl,
      om.publishDeviceImpl,
      commitDevice: commitDevice,
      commitRatchets: commitRatchets,
      commitDeviceList: commitDeviceList,
      removeRatchets: removeRatchets,
      loadRatchets: loadRatchets,
    ); 
   
    if (device == null) {
      await commitDevice(await _omemoManager.getDevice());
    }

    await _lock.synchronized(() {
      _initialized = true;

      for (final c in _waitingForInitialization) {
        c.complete();
      }
      _waitingForInitialization.clear();
    });
  }

  /// Adds a pseudo message saying that [jid] added a new device with id [deviceId].
  /// If, however, [jid] is our own JID, then nothing is done.
  Future<void> addNewDeviceMessage(String jid, int deviceId) async {
    // Add a pseudo message if it is not about our own devices
    final xmppState = await GetIt.I.get<XmppStateService>().getXmppState();
    if (jid == xmppState.jid) return;

    final ms = GetIt.I.get<MessageService>();
    final message = await ms.addMessageFromData(
      '',
      DateTime.now().millisecondsSinceEpoch,
      '',
      jid,
      '',
      false,
      false,
      false,
      pseudoMessageType: pseudoMessageTypeNewDevice,
      pseudoMessageData: <String, dynamic>{
        'deviceId': deviceId,
        'jid': jid,
      },
    );
    sendEvent(
      MessageAddedEvent(
        message: message,
      ),
    );
  }  
}
