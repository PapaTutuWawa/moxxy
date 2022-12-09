import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/moxxmpp/omemo.dart';
import 'package:moxxyv2/service/omemo/implementations.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:omemo_dart/omemo_dart.dart';
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
  final Queue<Completer<void>> _waitingForInitialization = Queue<Completer<void>>();

  late OmemoSessionManager omemoState;
  
  Future<void> initializeIfNeeded(String jid) async {
    final done = await _lock.synchronized(() => _initialized);
    if (done) return;

    final db = GetIt.I.get<DatabaseService>();
    final device = await db.loadOmemoDevice(jid);
    if (device == null) {
      _log.info('No OMEMO marker found. Generating OMEMO identity...');
      // Generate the identity in the background
      omemoState = await compute(generateNewIdentityImpl, jid);

      await commitDevice(await omemoState.getDevice());
      await commitDeviceMap(<String, List<int>>{});
      await commitTrustManager(await omemoState.trustManager.toJson());
    } else {
      _log.info('OMEMO marker found. Restoring OMEMO state...');
      final ratchetMap = <RatchetMapKey, OmemoDoubleRatchet>{};
      for (final ratchet in await GetIt.I.get<DatabaseService>().loadRatchets()) {
        final key = RatchetMapKey(ratchet.jid, ratchet.id);
        ratchetMap[key] = ratchet.ratchet;
      }

      final db = GetIt.I.get<DatabaseService>();
      omemoState = OmemoSessionManager(
        device,
        await db.loadOmemoDeviceList(),
        ratchetMap,
        await loadTrustManager(),
      );
    }

    omemoState.eventStream.listen((event) async {
      if (event is RatchetModifiedEvent) {
        await GetIt.I.get<DatabaseService>().saveRatchet(
          OmemoDoubleRatchetWrapper(event.ratchet, event.deviceId, event.jid),
        );
      } else if (event is DeviceMapModifiedEvent) {
        await commitDeviceMap(event.map);
      } else if (event is DeviceModifiedEvent) {
        await commitDevice(event.device);

        // Publish it
        await GetIt.I.get<XmppConnection>()
          .getManagerById<OmemoManager>(omemoManager)!
          .publishBundle(await event.device.toBundle());
      }
    });
    
    await _lock.synchronized(() {
      _initialized = true;

      for (final c in _waitingForInitialization) {
        c.complete();
      }
      _waitingForInitialization.clear();
    });
  }

  Future<OmemoDevice> regenerateDevice(String jid) async {
    // Prevent access to the session manager as it is (mostly) guarded ensureInitialized
    await _lock.synchronized(() {
      _initialized = false;
    });

    _log.info('No OMEMO marker found. Generating OMEMO identity...');
    final oldId = await omemoState.getDeviceId();

    // Clear the database
    await GetIt.I.get<DatabaseService>().emptyOmemoSessionTables();
    
    // Regenerate the identity in the background
    omemoState = await compute(generateNewIdentityImpl, jid);

    await commitDevice(await omemoState.getDevice());
    await commitDeviceMap(<String, List<int>>{});
    await commitTrustManager(await omemoState.trustManager.toJson());

    // Remove the old device
    final omemo = GetIt.I.get<XmppConnection>()
      .getManagerById<OmemoManager>(omemoManager)!;
    await omemo.deleteDevice(oldId);

    // Publish the new one
    await omemo.publishBundle(await omemoState.getDeviceBundle());
    
    // Allow access again
    await _lock.synchronized(() {
      _initialized = true;

      for (final c in _waitingForInitialization) {
        c.complete();
      }
      _waitingForInitialization.clear();
    });

    // Return the OmemoDevice
    return OmemoDevice(
      await getDeviceFingerprint(),
      true,
      true,
      true,
      await getDeviceId(),
    );
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
  
  Future<void> commitDeviceMap(Map<String, List<int>> deviceMap) async {
    await GetIt.I.get<DatabaseService>().saveOmemoDeviceList(deviceMap);
  }
  
  Future<void> commitDevice(Device device) async {
    await GetIt.I.get<DatabaseService>().saveOmemoDevice(device);
  }

  /// Requests our device list and checks if the current device is in it. If not, then
  /// it will be published.
  Future<Object?> publishDeviceIfNeeded() async {
    _log.finest('publishDeviceIfNeeded: Waiting for initialization...');
    await ensureInitialized();
    _log.finest('publishDeviceIfNeeded: Done');

    final conn = GetIt.I.get<XmppConnection>();
    final omemo = conn.getManagerById<OmemoManager>(omemoManager)!;
    final dm = conn.getManagerById<DiscoManager>(discoManager)!;
    final bareJid = conn.getConnectionSettings().jid.toBare();
    final device = await omemoState.getDevice();

    final bundlesRaw = await dm.discoItemsQuery(
      bareJid.toString(),
      node: omemoBundlesXmlns,
    );
    if (bundlesRaw.isType<DiscoError>()) {
      await omemo.publishBundle(await device.toBundle());
      return bundlesRaw.get<DiscoError>();
    }

    final bundleIds = bundlesRaw
      .get<List<DiscoItem>>()
      .where((item) => item.name != null)
      .map((item) => int.parse(item.name!));
    if (!bundleIds.contains(device.id)) {
      final result = await omemo.publishBundle(await device.toBundle());
      if (result.isType<OmemoError>()) return result.get<OmemoError>();
      return null;
    }
    
    final idsRaw = await omemo.getDeviceList(bareJid);
    final ids = idsRaw.isType<OmemoError>() ? <int>[] : idsRaw.get<List<int>>();
    if (!ids.contains(device.id)) {
      final result = await omemo.publishBundle(await device.toBundle());
      if (result.isType<OmemoError>()) return result.get<OmemoError>();
      return null;
    }

    return null;
  }

  Future<List<OmemoDevice>> getOmemoKeysForJid(String jid) async {
    await ensureInitialized();
    final fingerprints = await omemoState.getHexFingerprintsForJid(jid);
    final keys = List<OmemoDevice>.empty(growable: true);
    final tm = omemoState.trustManager as BlindTrustBeforeVerificationTrustManager;
    // TODO(PapaTutuWawa): This feels hacky
    final trustMap = await tm.getDevicesTrust(jid);
    for (final fp in fingerprints) {
      keys.add(
        OmemoDevice(
          fp.fingerprint,
          await tm.isTrusted(jid, fp.deviceId),
          trustMap[fp.deviceId]! == BTBVTrustState.verified,
          await tm.isEnabled(jid, fp.deviceId),
          fp.deviceId,
        ),
      );
    }

    return keys;
  }

  Future<void> commitTrustManager(Map<String, dynamic> json) async {
    await GetIt.I.get<DatabaseService>().saveTrustCache(
      json['trust']! as Map<String, int>,
    );
    await GetIt.I.get<DatabaseService>().saveTrustEnablementList(
      json['enable']! as Map<String, bool>,
    );
    await GetIt.I.get<DatabaseService>().saveTrustDeviceList(
      json['devices']! as Map<String, List<int>>,
    );
  }

  Future<MoxxyBTBVTrustManager> loadTrustManager() async {
    final db = GetIt.I.get<DatabaseService>();
    return MoxxyBTBVTrustManager(
      await db.loadTrustCache(),
      await db.loadTrustEnablementList(),
      await db.loadTrustDeviceList(),
    );
  }
  
  Future<void> setOmemoKeyEnabled(String jid, int deviceId, bool enabled) async {
    await ensureInitialized();
    await omemoState.trustManager.setEnabled(jid, deviceId, enabled);
  }

  Future<void> removeAllSessions(String jid) async {
    await ensureInitialized();
    await omemoState.removeAllRatchets(jid);
  }

  Future<int> getDeviceId() async {
    await ensureInitialized();
    return omemoState.getDeviceId();
  }
  
  Future<String> getDeviceFingerprint() async {
    return (await omemoState.getHexFingerprintForDevice()).fingerprint;
  }

  /// Returns a list of OmemoDevices for devices we have sessions with and other devices
  /// published on [ownJid]'s devices PubSub node.
  /// Note that the list is made so that the current device is excluded.
  Future<List<OmemoDevice>> getOwnFingerprints(JID ownJid) async {
    final conn = GetIt.I.get<XmppConnection>();
    final ownId = await getDeviceId();
    final keys = List<OmemoDevice>.from(
      await getOmemoKeysForJid(ownJid.toString()),
    );

    // TODO(PapaTutuWawa): This should be cached in the database and only requested if
    //                     it's not cached.
    final allDevicesRaw = await conn.getManagerById<OmemoManager>(omemoManager)!
      .retrieveDeviceBundles(ownJid);
    if (allDevicesRaw.isType<List<OmemoBundle>>()) {
      final allDevices = allDevicesRaw.get<List<OmemoBundle>>();

      for (final device in allDevices) {
        // All devices that are publishes that is not the current device
        if (device.id == ownId) continue;
        final curveIk = await device.ik.toCurve25519();
        
        keys.add(
          OmemoDevice(
            HEX.encode(await curveIk.getBytes()),
            false,
            false,
            false,
            device.id,
            hasSessionWith: false,
          ),
        );
      }
    }

    return keys;
  }

  Future<void> verifyDevice(int deviceId, String jid) async {
    final tm = omemoState.trustManager as BlindTrustBeforeVerificationTrustManager;
    await tm.setDeviceTrust(
      jid,
      deviceId,
      BTBVTrustState.verified,
    );
  }
}
