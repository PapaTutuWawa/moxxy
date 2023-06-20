import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/omemo/implementations.dart';
import 'package:moxxyv2/service/omemo/persistence.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart' as model;
import 'package:omemo_dart/omemo_dart.dart';
import 'package:synchronized/synchronized.dart';

class OmemoService {
  /// Logger.
  final Logger _log = Logger('OmemoService');

  /// Flag indicating whether we are initialized.
  bool _initialized = false;

  /// Flag indicating whether the initialization is currently running.
  bool _running = false;

  /// Lock guarding access to [_waitingForInitialization], [_running], and [_initialized].
  final Lock _lock = Lock();

  /// Queue for code that is waiting on the service initialization.
  final Queue<Completer<void>> _waitingForInitialization =
      Queue<Completer<void>>();

  /// The manager to use for OMEMO.
  late OmemoManager _omemoManager;

  /// Access the underlying [OmemoManager].
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

  /// Creates or loads the [OmemoManager] for the JID [jid].
  Future<void> initializeIfNeeded(String jid) async {
    final done = await _lock.synchronized(() {
      // Do nothing if we're already initialized
      if (_initialized) {
        return true;
      }

      // Lock the execution if we're not yet running.
      if (_running) {
        return true;
      }
      _running = true;
      return false;
    });
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
      _running = false;
      _initialized = true;

      for (final c in _waitingForInitialization) {
        c.complete();
      }
      _waitingForInitialization.clear();
    });
  }

  Future<moxxmpp.OmemoError?> publishDeviceIfNeeded() async {
    _log.finest('publishDeviceIfNeeded: Waiting for initialization...');
    await ensureInitialized();
    _log.finest('publishDeviceIfNeeded: Done');

    final conn = GetIt.I.get<moxxmpp.XmppConnection>();
    final omemo =
        conn.getManagerById<moxxmpp.OmemoManager>(moxxmpp.omemoManager)!;
    final dm = conn.getManagerById<moxxmpp.DiscoManager>(moxxmpp.discoManager)!;
    final bareJid = conn.connectionSettings.jid.toBare();
    final device = await _omemoManager.getDevice();

    final bundlesRaw = await dm.discoItemsQuery(
      bareJid,
      node: moxxmpp.omemoBundlesXmlns,
    );
    if (bundlesRaw.isType<moxxmpp.DiscoError>()) {
      await omemo.publishBundle(await device.toBundle());
      return null;
    }

    final bundleIds = bundlesRaw
        .get<List<moxxmpp.DiscoItem>>()
        .where((item) => item.name != null)
        .map((item) => int.parse(item.name!));
    if (!bundleIds.contains(device.id)) {
      final result = await omemo.publishBundle(await device.toBundle());
      if (result.isType<moxxmpp.OmemoError>()) {
        return result.get<moxxmpp.OmemoError>();
      }
      return null;
    }

    final idsRaw = await omemo.getDeviceList(bareJid);
    final ids =
        idsRaw.isType<moxxmpp.OmemoError>() ? <int>[] : idsRaw.get<List<int>>();
    if (!ids.contains(device.id)) {
      final result = await omemo.publishBundle(await device.toBundle());
      if (result.isType<moxxmpp.OmemoError>()) {
        return result.get<moxxmpp.OmemoError>();
      }
      return null;
    }

    return null;
  }

  Future<void> onNewConnection() async {
    await ensureInitialized();
    await _omemoManager.onNewConnection();
  }

  Future<List<model.OmemoDevice>> getFingerprintsForJid(String jid) async {
    await ensureInitialized();
    final fingerprints = await _omemoManager.getFingerprintsForJid(jid) ?? [];
    var trust = <int, BTBVTrustData>{};

    await _omemoManager.withTrustManager(
      jid,
      (tm) async {
        trust = await (tm as BlindTrustBeforeVerificationTrustManager)
            .getDevicesTrust(jid);
      },
    );

    return fingerprints.map((fp) {
      return model.OmemoDevice(
        fp.fingerprint,
        trust[fp.deviceId]?.trusted ?? false,
        trust[fp.deviceId]?.state == BTBVTrustState.verified,
        trust[fp.deviceId]?.enabled ?? false,
        fp.deviceId,
      );
    }).toList();
  }

  Future<void> setDeviceEnablement(String jid, int device, bool state) async {
    await ensureInitialized();
    await _omemoManager.withTrustManager(jid, (tm) async {
      await (tm as BlindTrustBeforeVerificationTrustManager)
          .setEnabled(jid, device, state);
    });
  }

  Future<void> setDeviceVerified(String jid, int device) async {
    await ensureInitialized();
    await _omemoManager.withTrustManager(jid, (tm) async {
      await (tm as BlindTrustBeforeVerificationTrustManager)
          .setDeviceTrust(jid, device, BTBVTrustState.verified);
    });
  }

  Future<void> removeAllRatchets(String jid) async {
    await ensureInitialized();
    await _omemoManager.removeAllRatchets(jid);
  }

  Future<OmemoDevice> getDevice() async {
    await ensureInitialized();
    return _omemoManager.getDevice();
  }

  Future<model.OmemoDevice> regenerateDevice() async {
    await ensureInitialized();

    final oldDeviceId = (await getDevice()).id;

    // Generate the new device
    final newDevice = await _omemoManager.regenerateDevice();

    // Remove the old device
    unawaited(
      GetIt.I
          .get<moxxmpp.XmppConnection>()
          .getManagerById<moxxmpp.OmemoManager>(moxxmpp.omemoManager)!
          .deleteDevice(oldDeviceId),
    );

    return model.OmemoDevice(
      await newDevice.getFingerprint(),
      true,
      true,
      true,
      newDevice.id,
    );
  }

  /// Adds a pseudo-message of type [type] to the chat with [conversationJid].
  /// Also sends an event to the UI.
  Future<void> addPseudoMessage(
    String conversationJid,
    PseudoMessageType type,
  ) async {
    final ms = GetIt.I.get<MessageService>();
    final message = await ms.addMessageFromData(
      '',
      DateTime.now().millisecondsSinceEpoch,
      '',
      conversationJid,
      '',
      false,
      false,
      false,
      pseudoMessageType: type,
    );
    sendEvent(
      MessageAddedEvent(
        message: message,
      ),
    );
  }
}
