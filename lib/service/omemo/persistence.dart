import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:omemo_dart/omemo_dart.dart';
import 'package:sqflite_common/sql.dart';

extension ByteListHelpers on List<int> {
  String toBase64() {
    return base64Encode(this);
  }

  OmemoPublicKey toPublicKey(KeyPairType type) {
    return OmemoPublicKey.fromBytes(this, type);
  }
}

Future<void> commitDevice(OmemoDevice device) async {
  final db = GetIt.I.get<DatabaseService>().database;
  final serializedOpks = <String, Map<String, String>>{};
  for (final entry in device.opks.entries) {
    serializedOpks[entry.key.toString()] = {
      'public': base64Encode(await entry.value.pk.getBytes()),
      'private': base64Encode(await entry.value.sk.getBytes()),
    };
  }

  await db.insert(
    omemoDevicesTable,
    {
      'jid': device.jid,
      'id': device.id,
      'ikPub': base64Encode(await device.ik.pk.getBytes()),
      'ik': base64Encode(await device.ik.sk.getBytes()),
      'spkPub': base64Encode(await device.spk.pk.getBytes()),
      'spk': base64Encode(await device.spk.sk.getBytes()),
      'spkId': device.spkId,
      'spkSig': base64Encode(device.spkSignature),
      'oldSpkPub': (await device.oldSpk?.pk.getBytes())?.toBase64(),
      'oldSpk': (await device.oldSpk?.sk.getBytes())?.toBase64(),
      'oldSpkId': device.oldSpkId,
      'opks': jsonEncode(serializedOpks),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<OmemoDevice?> loadOmemoDevice(String jid) async {
  final db = GetIt.I.get<DatabaseService>().database;
  final rawDevice = await db.query(
    omemoDevicesTable,
    where: 'jid = ?',
    whereArgs: [jid],
    limit: 1,
  );
  if (rawDevice.isEmpty) {
    return null;
  }

  final deviceJson = rawDevice.first;

  // Deserialize the OPKs first
  final deserializedOpks = <int, OmemoKeyPair>{};
  final opks =
      (jsonDecode(rawDevice.first['opks']! as String) as Map<dynamic, dynamic>)
          .cast<String, dynamic>();
  for (final opk in opks.entries) {
    final opkValue = (opk.value as Map<String, dynamic>).cast<String, String>();
    deserializedOpks[int.parse(opk.key)] = OmemoKeyPair.fromBytes(
      base64Decode(opkValue['public']!),
      base64Decode(opkValue['private']!),
      KeyPairType.x25519,
    );
  }

  OmemoKeyPair? oldSpk;
  if (deviceJson['oldSpkPub'] != null && deviceJson['oldSpk'] != null) {
    oldSpk = OmemoKeyPair.fromBytes(
      base64Decode(deviceJson['oldSpkPub']! as String),
      base64Decode(deviceJson['oldSpk']! as String),
      KeyPairType.x25519,
    );
  }

  return OmemoDevice(
    jid,
    deviceJson['id']! as int,
    OmemoKeyPair.fromBytes(
      base64Decode(deviceJson['ikPub']! as String),
      base64Decode(deviceJson['ik']! as String),
      KeyPairType.ed25519,
    ),
    OmemoKeyPair.fromBytes(
      base64Decode(deviceJson['spkPub']! as String),
      base64Decode(deviceJson['spk']! as String),
      KeyPairType.x25519,
    ),
    deviceJson['spkId']! as int,
    base64Decode(deviceJson['spkSig']! as String),
    oldSpk,
    deviceJson['oldSpkId'] as int?,
    deserializedOpks,
  );
}

Future<void> commitRatchets(List<OmemoRatchetData> ratchets) async {
  final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
  final db = GetIt.I.get<DatabaseService>().database;
  final batch = db.batch();
  for (final ratchet in ratchets) {
    // Serialize the skipped keys
    final serializedSkippedKeys = <Map<String, Object>>[];
    for (final sk in ratchet.ratchet.mkSkipped.entries) {
      serializedSkippedKeys.add({
        'dhPub': (await sk.key.dh.getBytes()).toBase64(),
        'n': sk.key.n,
        'mk': sk.value.toBase64(),
      });
    }

    // Serialize the KEX
    final kex = {
      'pkId': ratchet.ratchet.kex.pkId,
      'spkId': ratchet.ratchet.kex.spkId,
      'ek': (await ratchet.ratchet.kex.ek.getBytes()).toBase64(),
      'ik': (await ratchet.ratchet.kex.ik.getBytes()).toBase64(),
    };

    batch.insert(
      omemoRatchetsTable,
      {
        'jid': ratchet.jid,
        'device': ratchet.id,
        'dhsPub': base64Encode(await ratchet.ratchet.dhs.pk.getBytes()),
        'dhs': base64Encode(await ratchet.ratchet.dhs.sk.getBytes()),
        'dhrPub': (await ratchet.ratchet.dhr?.getBytes())?.toBase64(),
        'rk': base64Encode(ratchet.ratchet.rk),
        'cks': ratchet.ratchet.cks?.toBase64(),
        'ckr': ratchet.ratchet.ckr?.toBase64(),
        'ns': ratchet.ratchet.ns,
        'nr': ratchet.ratchet.nr,
        'pn': ratchet.ratchet.pn,
        'ik': (await ratchet.ratchet.ik.getBytes()).toBase64(),
        'ad': ratchet.ratchet.sessionAd.toBase64(),
        'skipped': jsonEncode(serializedSkippedKeys),
        'kex': jsonEncode(kex),
        'acked': boolToInt(ratchet.ratchet.acknowledged),
        'accountJid': accountJid,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  await batch.commit();
}

Future<void> commitDeviceList(String jid, List<int> devices) async {
  final db = GetIt.I.get<DatabaseService>().database;
  await db.insert(
    omemoDeviceListTable,
    {
      'jid': jid,
      'devices': jsonEncode(devices),
      'accountJid': await GetIt.I.get<XmppStateService>().getAccountJid(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> removeRatchets(List<RatchetMapKey> ratchets) async {
  final db = GetIt.I.get<DatabaseService>().database;
  final batch = db.batch();

  for (final key in ratchets) {
    batch.delete(
      omemoRatchetsTable,
      where: 'jid = ? AND device = ? AND accountJid = ?',
      whereArgs: [
        key.jid,
        key.deviceId,
        await GetIt.I.get<XmppStateService>().getAccountJid(),
      ],
    );
  }

  await batch.commit();
}

Future<OmemoDataPackage?> loadRatchets(String jid) async {
  final accountJid = await GetIt.I.get<XmppStateService>().getAccountJid();
  final db = GetIt.I.get<DatabaseService>().database;
  final ratchetsRaw = await db.query(
    omemoRatchetsTable,
    where: 'jid = ? AND accountJid = ?',
    whereArgs: [jid, accountJid],
  );
  final deviceListRaw = await db.query(
    omemoDeviceListTable,
    where: 'jid = ? AND accountJid = ?',
    whereArgs: [jid, accountJid],
    limit: 1,
  );
  if (ratchetsRaw.isEmpty || deviceListRaw.isEmpty) {
    return null;
  }

  // Deserialize the ratchets
  final ratchets = <RatchetMapKey, OmemoDoubleRatchet>{};
  for (final ratchetRaw in ratchetsRaw) {
    final key = RatchetMapKey(
      jid,
      ratchetRaw['device']! as int,
    );

    // Deserialize skipped keys
    final mkSkipped = <SkippedKey, List<int>>{};
    final skippedKeysRaw =
        (jsonDecode(ratchetRaw['skipped']! as String) as List<dynamic>)
            .cast<Map<dynamic, dynamic>>();
    for (final skippedRaw in skippedKeysRaw) {
      final key = SkippedKey(
        (skippedRaw['dhPub']! as String)
            .fromBase64()
            .toPublicKey(KeyPairType.x25519),
        skippedRaw['n']! as int,
      );
      mkSkipped[key] = (skippedRaw['mk']! as String).fromBase64();
    }

    // Deserialize the KEX
    final kexRaw =
        (jsonDecode(ratchetRaw['kex']! as String) as Map<dynamic, dynamic>)
            .cast<String, Object>();
    final kex = KeyExchangeData(
      kexRaw['pkId']! as int,
      kexRaw['spkId']! as int,
      (kexRaw['ek']! as String).fromBase64().toPublicKey(KeyPairType.x25519),
      (kexRaw['ik']! as String).fromBase64().toPublicKey(KeyPairType.ed25519),
    );

    // Deserialize the entire ratchet
    ratchets[key] = OmemoDoubleRatchet(
      OmemoKeyPair.fromBytes(
        base64Decode(ratchetRaw['dhsPub']! as String),
        base64Decode(ratchetRaw['dhs']! as String),
        KeyPairType.x25519,
      ),
      (ratchetRaw['dhrPub'] as String?)
          ?.fromBase64()
          .toPublicKey(KeyPairType.x25519),
      base64Decode(ratchetRaw['rk']! as String),
      (ratchetRaw['cks'] as String?)?.fromBase64(),
      (ratchetRaw['ckr'] as String?)?.fromBase64(),
      ratchetRaw['ns']! as int,
      ratchetRaw['nr']! as int,
      ratchetRaw['pn']! as int,
      (ratchetRaw['ik']! as String)
          .fromBase64()
          .toPublicKey(KeyPairType.ed25519),
      (ratchetRaw['ad']! as String).fromBase64(),
      mkSkipped,
      intToBool(ratchetRaw['acked']! as int),
      kex,
    );
  }

  return OmemoDataPackage(
    (jsonDecode(deviceListRaw.first['devices']! as String) as List<dynamic>)
        .cast<int>(),
    ratchets,
  );
}

Future<void> commitTrust(BTBVTrustData trust) async {
  final db = GetIt.I.get<DatabaseService>().database;
  await db.insert(
    omemoTrustTable,
    {
      'jid': trust.jid,
      'device': trust.device,
      'trust': trust.state.value,
      'enabled': boolToInt(trust.enabled),
      'accountJid': await GetIt.I.get<XmppStateService>().getAccountJid(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<BTBVTrustData>> loadTrust(String jid) async {
  final db = GetIt.I.get<DatabaseService>().database;
  final rawTrust = await db.query(
    omemoTrustTable,
    where: 'jid = ? AND accountJid = ?',
    whereArgs: [jid, await GetIt.I.get<XmppStateService>().getAccountJid()],
  );

  return rawTrust.map((trust) {
    return BTBVTrustData(
      jid,
      trust['device']! as int,
      BTBVTrustState.fromInt(trust['trust']! as int),
      intToBool(trust['enabled']! as int),
      false,
    );
  }).toList();
}

Future<void> removeTrust(String jid) async {
  final db = GetIt.I.get<DatabaseService>().database;
  await db.delete(
    omemoTrustTable,
    where: 'jid = ? AND accountJid = ?',
    whereArgs: [jid, await GetIt.I.get<XmppStateService>().getAccountJid()],
  );
}
