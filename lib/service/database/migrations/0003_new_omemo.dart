import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV39ToV40(Database db) async {
  // Remove the old tables
  await db.execute('DROP TABLE OmemoDevices');
  await db.execute('DROP TABLE OmemoDeviceList');
  await db.execute('DROP TABLE OmemoTrustCacheList');
  await db.execute('DROP TABLE OmemoTrustDeviceList');
  await db.execute('DROP TABLE OmemoTrustEnableList');
  await db.execute('DROP TABLE OmemoFingerprintCache');

  // Create the new tables
  await db.execute(
    '''
    CREATE TABLE $omemoDevicesTable (
      jid       TEXT NOT NULL PRIMARY KEY,
      id        INTEGER NOT NULL,
      ikPub     TEXT NOT NULL,
      ik        TEXT NOT NULL,
      spkPub    TEXT NOT NULL,
      spk       TEXT NOT NULL,
      spkId     INTEGER NOT NULL,
      spkSig    TEXT NOT NULL,
      oldSpkPub TEXT,
      oldSpk    TEXT,
      oldSpkId  INTEGER,
      opks      TEXT NOT NULL
    )''',
  );

  await db.execute(
    '''
    CREATE TABLE $omemoDeviceListTable (
      jid     TEXT NOT NULL PRIMARY KEY,
      devices TEXT NOT NULL
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoRatchetsTable (
      jid TEXT NOT NULL,
      device INTEGER NOT NULL,
      dhsPub  TEXT NOT NULL,
      dhs     TEXT NOT NULL,
      dhrPub  TEXT,
      rk      TEXT NOT NULL,
      cks     TEXT,
      ckr     TEXT,
      ns      INTEGER NOT NULL,
      nr      INTEGER NOT NULL,
      pn      INTEGER NOT NULL,
      ik      TEXT NOT NULL,
      ad      TEXT NOT NULL,
      skipped TEXT NOT NULL,
      kex     TEXT NOT NULL,
      acked   INTEGER NOT NULL,
      PRIMARY KEY (jid, device)
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoTrustTable (
      jid     TEXT NOT NULL,
      device  INTEGER NOT NULL,
      trust   INTEGER NOT NULL,
      enabled INTEGER NOT NULL,
      PRIMARY KEY (jid, device)
    )''',
  );
}
