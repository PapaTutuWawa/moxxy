import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/omemo_key.dart';
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384/xep_0384.dart';
import 'package:omemo_dart/omemo_dart.dart';

class OmemoDoubleRatchetWrapper {

  OmemoDoubleRatchetWrapper(this.ratchet, this.id, this.jid);
  final OmemoDoubleRatchet ratchet;
  final int id;
  final String jid;
}

const _omemoStorageMarker = 'omemo_marker';
const _omemoStorageDevice = 'omemo_device';
const _omemoStorageDeviceMap = 'omemo_device_map';

class OmemoService {

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final Logger _log = Logger('OmemoService');
  bool initialized = false;
  late OmemoSessionManager omemoState;
  
  Future<void> initialize(String jid) async {
    if (!(await _storage.containsKey(key: _omemoStorageMarker))) {
      _log.info('No OMEMO marker found. Generating OMEMO identity...');
      omemoState = await OmemoSessionManager.generateNewIdentity(
        jid,
        // TODO(PapaTutuWawa): Subclass
        MemoryBTBVTrustManager(),
      );

      final device = await omemoState.getDevice();
      
      await _storage.write(key: _omemoStorageMarker, value: 'true');
      await _storage.write(
        key: _omemoStorageDevice,
        value: jsonEncode(await device.toJson()),
      );
      await _storage.write(
        key: _omemoStorageDeviceMap,
        value: '{}',
      );
    } else {
      _log.info('OMEMO marker found. Restoring OMEMO state...');
      final deviceString = await _storage.read(key: _omemoStorageDevice);
      final deviceJson = jsonDecode(deviceString!) as Map<String, dynamic>;

      // NOTE: We need to do this because Dart otherwise complains about not being able
      //       to cast dynamic to List<int>.
      final opks = List<Map<String, dynamic>>.empty(growable: true);
      for (final Map<String, dynamic> opk in deviceJson['opks']! as List<dynamic>) {
        opks.add(<String, dynamic>{
          'id': opk['id']! as int,
          'public': opk['public']! as String,
          'private': opk['private']! as String,
        });
      }
      deviceJson['opks'] = opks;
      final device = Device.fromJson(deviceJson);

      final ratchetMap = <RatchetMapKey, OmemoDoubleRatchet>{};
      for (final ratchet in await GetIt.I.get<DatabaseService>().loadRatchets()) {
        final key = RatchetMapKey(ratchet.jid, ratchet.id);
        ratchetMap[key] = ratchet.ratchet;
      }

      final deviceMapString = await _storage.read(key: _omemoStorageDeviceMap);
      // ignore: argument_type_not_assignable
      final deviceMapJson = Map<String, List<int>>.from(jsonDecode(deviceMapString!));
      _log.finest(deviceMapJson);
      omemoState = OmemoSessionManager(
        device,
        deviceMapJson,
        ratchetMap,
        // TODO(PapaTutuWawa): Subclass
        MemoryBTBVTrustManager(),
      );
    }


    initialized = true;
  }

  Future<void> commitDeviceMap(Map<String, List<int>> deviceMap) async {
    await _storage.write(
      key: _omemoStorageDeviceMap,
      value: jsonEncode(deviceMap),
    );
  }
  
  Future<void> commitDevice(Device device) async {
    await _storage.write(
      key: _omemoStorageDevice,
      value: jsonEncode(await device.toJson()),
    );
  }

  /// Requests our device list and checks if the current device is in it. If not, then
  /// it will be published.
  Future<void> publishDeviceIfNeeded() async {
    final conn = GetIt.I.get<XmppConnection>();
    final omemo = conn.getManagerById<OmemoManager>(omemoManager)!;
    final bareJid = conn.getConnectionSettings().jid.toBare();
    final ids = (await omemo.getDeviceList(bareJid)) ?? [];
    final device = await omemoState.getDevice();
    if (!ids.contains(device.id)) {
      await omemo.publishBundle(await device.toBundle());
    }
  }

  Future<List<OmemoKey>> getOmemoKeysForJid(String jid) async {
    final fingerprints = await omemoState.getHexFingerprintsForJid(jid);
    final keys = List<OmemoKey>.empty(growable: true);
    for (final fp in fingerprints) {
      keys.add(
        OmemoKey(
          fp.fingerprint,
          await omemoState.trustManager.isTrusted(jid, fp.deviceId),
          // TODO(Unknown): Allow verifying OMEMO keys
          false,
        ),
      );
    }

    return keys;
  }
}
