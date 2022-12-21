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
import 'package:moxxyv2/service/omemo/types.dart';
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
  final Map<String, Map<int, String>> _fingerprintCache = {};

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

        if (event.added) {
          // Cache the fingerprint
          final fingerprint = HEX.encode(await event.ratchet.ik.getBytes());
          await GetIt.I.get<DatabaseService>().addFingerprintsToCache([
            OmemoCacheTriple(
              event.jid,
              event.deviceId,
              fingerprint,
            ),
          ]);

          if (_fingerprintCache.containsKey(event.jid)) {
            _fingerprintCache[event.jid]![event.deviceId] = fingerprint;
          }
        }
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

  Future<void> _fetchFingerprintsAndCache(JID jid) async {
    final bareJid = jid.toBare().toString();
    final allDevicesRaw = await GetIt.I.get<XmppConnection>()
      .getManagerById<OmemoManager>(omemoManager)!
      .retrieveDeviceBundles(jid);
    if (allDevicesRaw.isType<List<OmemoBundle>>()) {
      final allDevices = allDevicesRaw.get<List<OmemoBundle>>();
      final map = <int, String>{};
      final items = List<OmemoCacheTriple>.empty(growable: true);
      for (final device in allDevices) {
        final curveIk = await device.ik.toCurve25519();
        final fingerprint = HEX.encode(await curveIk.getBytes());
        map[device.id] = fingerprint;
        items.add(OmemoCacheTriple(bareJid, device.id, fingerprint));
      }

      // Cache them in memory
      _fingerprintCache[bareJid] = map;

      // Cache them in the database
      await GetIt.I.get<DatabaseService>().addFingerprintsToCache(items);
    }
  }

  Future<void> _loadOrFetchFingerprints(JID jid) async {
    final bareJid = jid.toBare().toString();
    if (!_fingerprintCache.containsKey(bareJid)) {
      // First try to load it from the database
      final triples = await GetIt.I.get<DatabaseService>()
        .getFingerprintsFromCache(bareJid);
      if (triples.isEmpty) {
        // We found no fingerprints in the database, so try to fetch them
        await _fetchFingerprintsAndCache(jid);
      } else {
        // We have fetched fingerprints from the database
        _fingerprintCache[bareJid] = Map<int, String>.fromEntries(
          triples.map((triple) {
            return MapEntry<int, String>(
              triple.deviceId,
              triple.fingerprint,
            );
          }),
        );
      }
    }
  }
  
  Future<List<OmemoDevice>> getOmemoKeysForJid(String jid) async {
    await ensureInitialized();

    // Get finger prints if we have to
    await _loadOrFetchFingerprints(JID.fromString(jid));
    
    final keys = List<OmemoDevice>.empty(growable: true);
    final tm = omemoState.trustManager as BlindTrustBeforeVerificationTrustManager;
    final trustMap = await tm.getDevicesTrust(jid);
    for (final deviceId in _fingerprintCache[jid]!.keys) {
      keys.add(
        OmemoDevice(
          _fingerprintCache[jid]![deviceId]!,
          await tm.isTrusted(jid, deviceId),
          trustMap[deviceId] == BTBVTrustState.verified,
          await tm.isEnabled(jid, deviceId),
          deviceId,
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
    final ownId = await getDeviceId();
    final keys = List<OmemoDevice>.from(
      await getOmemoKeysForJid(ownJid.toString()),
    );
    final bareJid = ownJid.toBare().toString();

    // Get fingerprints if we have to
    await _loadOrFetchFingerprints(ownJid);
    
    _fingerprintCache[bareJid]!.forEach((deviceId, fingerprint) {
      if (deviceId == ownId) return;
      keys.add(
        OmemoDevice(
          fingerprint,
          false,
          false,
          false,
          deviceId,
          hasSessionWith: false,
        ),
      );
    });

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
