import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/moxxmpp/omemo.dart';
import 'package:moxxyv2/service/omemo/implementations.dart';
import 'package:moxxyv2/service/omemo/types.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart' as model;
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
  final Queue<Completer<void>> _waitingForInitialization =
      Queue<Completer<void>>();
  final Map<String, Map<int, String>> _fingerprintCache = {};

  late OmemoManager omemoManager;

  Future<void> initializeIfNeeded(String jid) async {
    final done = await _lock.synchronized(() => _initialized);
    if (done) return;

    final db = GetIt.I.get<DatabaseService>();
    final device = await db.loadOmemoDevice(jid);
    final ratchetMap = <RatchetMapKey, OmemoDoubleRatchet>{};
    final deviceList = <String, List<int>>{};
    if (device == null) {
      _log.info('No OMEMO marker found. Generating OMEMO identity...');
    } else {
      _log.info('OMEMO marker found. Restoring OMEMO state...');
      for (final ratchet
          in await GetIt.I.get<DatabaseService>().loadRatchets()) {
        final key = RatchetMapKey(ratchet.jid, ratchet.id);
        ratchetMap[key] = ratchet.ratchet;
      }

      deviceList.addAll(await db.loadOmemoDeviceList());
    }

    final om = GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.BaseOmemoManager>(moxxmpp.omemoManager)!;
    omemoManager = OmemoManager(
      device ?? await compute(generateNewIdentityImpl, jid),
      await loadTrustManager(),
      om.sendEmptyMessageImpl,
      om.fetchDeviceList,
      om.fetchDeviceBundle,
      om.subscribeToDeviceListImpl,
    );

    if (device == null) {
      await commitDevice(await omemoManager.getDevice());
      await commitDeviceMap(<String, List<int>>{});
      await commitTrustManager(await omemoManager.trustManager.toJson());
    }

    omemoManager.initialize(
      ratchetMap,
      deviceList,
    );

    omemoManager.eventStream.listen((event) async {
      if (event is RatchetModifiedEvent) {
        await GetIt.I.get<DatabaseService>().saveRatchet(
              OmemoDoubleRatchetWrapper(
                event.ratchet,
                event.deviceId,
                event.jid,
              ),
            );

        if (event.added) {
          // Cache the fingerprint
          final fingerprint = await event.ratchet.getOmemoFingerprint();
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

          await addNewDeviceMessage(event.jid, event.deviceId);
        }
      } else if (event is DeviceListModifiedEvent) {
        await commitDeviceMap(event.list);
      } else if (event is DeviceModifiedEvent) {
        await commitDevice(event.device);

        // Publish it
        await GetIt.I
            .get<moxxmpp.XmppConnection>()
            .getManagerById<moxxmpp.BaseOmemoManager>(moxxmpp.omemoManager)!
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
      false,
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

  Future<model.OmemoDevice> regenerateDevice(String jid) async {
    // Prevent access to the session manager as it is (mostly) guarded ensureInitialized
    await _lock.synchronized(() {
      _initialized = false;
    });

    _log.info('No OMEMO marker found. Generating OMEMO identity...');
    final oldId = await omemoManager.getDeviceId();

    // Clear the database
    await GetIt.I.get<DatabaseService>().emptyOmemoSessionTables();

    // Regenerate the identity in the background
    final device = await compute(generateNewIdentityImpl, jid);
    await omemoManager.replaceDevice(device);
    await commitDevice(device);
    await commitDeviceMap(<String, List<int>>{});
    await commitTrustManager(await omemoManager.trustManager.toJson());

    // Remove the old device
    final omemo = GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.BaseOmemoManager>(moxxmpp.omemoManager)!;
    await omemo.deleteDevice(oldId);

    // Publish the new one
    await omemo.publishBundle(await omemoManager.getDeviceBundle());

    // Allow access again
    await _lock.synchronized(() {
      _initialized = true;

      for (final c in _waitingForInitialization) {
        c.complete();
      }
      _waitingForInitialization.clear();
    });

    // Return the OmemoDevice
    return model.OmemoDevice(
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

  Future<void> commitDevice(OmemoDevice device) async {
    await GetIt.I.get<DatabaseService>().saveOmemoDevice(device);
  }

  /// Requests our device list and checks if the current device is in it. If not, then
  /// it will be published.
  Future<Object?> publishDeviceIfNeeded() async {
    _log.finest('publishDeviceIfNeeded: Waiting for initialization...');
    await ensureInitialized();
    _log.finest('publishDeviceIfNeeded: Done');

    final conn = GetIt.I.get<moxxmpp.XmppConnection>();
    final omemo =
        conn.getManagerById<moxxmpp.BaseOmemoManager>(moxxmpp.omemoManager)!;
    final dm = conn.getManagerById<moxxmpp.DiscoManager>(moxxmpp.discoManager)!;
    final bareJid = conn.getConnectionSettings().jid.toBare();
    final device = await omemoManager.getDevice();

    final bundlesRaw = await dm.discoItemsQuery(
      bareJid.toString(),
      node: moxxmpp.omemoBundlesXmlns,
    );
    if (bundlesRaw.isType<moxxmpp.DiscoError>()) {
      await omemo.publishBundle(await device.toBundle());
      return bundlesRaw.get<moxxmpp.DiscoError>();
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

  Future<void> _fetchFingerprintsAndCache(moxxmpp.JID jid) async {
    final bareJid = jid.toBare().toString();
    final allDevicesRaw = await GetIt.I
        .get<moxxmpp.XmppConnection>()
        .getManagerById<moxxmpp.BaseOmemoManager>(moxxmpp.omemoManager)!
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

  Future<void> _loadOrFetchFingerprints(moxxmpp.JID jid) async {
    final bareJid = jid.toBare().toString();
    if (!_fingerprintCache.containsKey(bareJid)) {
      // First try to load it from the database
      final triples = await GetIt.I
          .get<DatabaseService>()
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

  Future<List<model.OmemoDevice>> getOmemoKeysForJid(String jid) async {
    await ensureInitialized();

    // Get finger prints if we have to
    await _loadOrFetchFingerprints(moxxmpp.JID.fromString(jid));

    final keys = List<model.OmemoDevice>.empty(growable: true);
    final tm =
        omemoManager.trustManager as BlindTrustBeforeVerificationTrustManager;
    final trustMap = await tm.getDevicesTrust(jid);

    if (!_fingerprintCache.containsKey(jid)) return [];
    for (final deviceId in _fingerprintCache[jid]!.keys) {
      keys.add(
        model.OmemoDevice(
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

  Future<void> setOmemoKeyEnabled(
    String jid,
    int deviceId,
    bool enabled,
  ) async {
    await ensureInitialized();
    await omemoManager.trustManager.setEnabled(jid, deviceId, enabled);
  }

  Future<void> removeAllSessions(String jid) async {
    await ensureInitialized();
    await omemoManager.removeAllRatchets(jid);
  }

  Future<int> getDeviceId() async {
    await ensureInitialized();
    return omemoManager.getDeviceId();
  }

  Future<String> getDeviceFingerprint() => omemoManager.getDeviceFingerprint();

  /// Returns a list of OmemoDevices for devices we have sessions with and other devices
  /// published on [ownJid]'s devices PubSub node.
  /// Note that the list is made so that the current device is excluded.
  Future<List<model.OmemoDevice>> getOwnFingerprints(moxxmpp.JID ownJid) async {
    final ownId = await getDeviceId();
    final keys = List<model.OmemoDevice>.from(
      await getOmemoKeysForJid(ownJid.toString()),
    );
    final bareJid = ownJid.toBare().toString();

    // Get fingerprints if we have to
    await _loadOrFetchFingerprints(ownJid);

    final tm =
        omemoManager.trustManager as BlindTrustBeforeVerificationTrustManager;
    final trustMap = await tm.getDevicesTrust(bareJid);

    for (final deviceId in _fingerprintCache[bareJid]!.keys) {
      if (deviceId == ownId) continue;
      if (keys.indexWhere((key) => key.deviceId == deviceId) != -1) continue;

      final fingerprint = _fingerprintCache[bareJid]![deviceId]!;
      keys.add(
        model.OmemoDevice(
          fingerprint,
          await tm.isTrusted(bareJid, deviceId),
          trustMap[deviceId] == BTBVTrustState.verified,
          await tm.isEnabled(bareJid, deviceId),
          deviceId,
          hasSessionWith: false,
        ),
      );
    }

    return keys;
  }

  Future<void> verifyDevice(int deviceId, String jid) async {
    final tm =
        omemoManager.trustManager as BlindTrustBeforeVerificationTrustManager;
    await tm.setDeviceTrust(
      jid,
      deviceId,
      BTBVTrustState.verified,
    );
  }

  /// Tells omemo_dart, that certain caches are to be seen as invalidated.
  void onNewConnection() {
    if (_initialized) {
      omemoManager.onNewConnection();
    }
  }
}
