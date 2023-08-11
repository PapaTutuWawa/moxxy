import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/xmpp_state.dart';
import 'package:random_string/random_string.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

extension UserAgentJson on UserAgent {
  Map<String, String?> toJson() => {
        'id': id,
        'software': software,
        'device': device,
      };
}

const _userAgentKey = 'userAgent';

const _databasePasswordKey = 'database_encryption_password';
const _accountJidKey = 'account_jid';

class XmppStateService {
  /// Logger
  final Logger _log = Logger('XmppStateService');

  /// Persistent state around the connection, like the SM token, etc.
  XmppState? _state;

  /// Cached account JID.
  String? _accountJid;

  /// Cache the user agent
  UserAgent? _userAgent;
  final Lock _userAgentLock = Lock();

  /// Secure storage for data we must have before the database is up.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Either returns the database password from the secure storage or
  /// generates a new one and writes it to the secure storage.
  Future<String> getOrCreateDatabaseKey() async {
    final key = await _storage.read(key: _databasePasswordKey);
    if (key != null) {
      return key;
    }

    // We have no database key yet, so generate, save, and return.
    _log.info('Found no database encryption password. Generating a new one...');
    final newKey = randomAlphaNumeric(
      40,
      provider: CoreRandomProvider.from(Random.secure()),
    );
    await _storage.write(key: _databasePasswordKey, value: newKey);
    _log.info('Key generation done');
    return newKey;
  }

  /// The user agent used for SASL2 authentication. If cached, returns from cache.
  /// If not cached, loads from the database. If not in the database, creates a
  /// user agent and writes it to the database.
  Future<UserAgent> get userAgent async {
    return _userAgentLock.synchronized(() async {
      if (_userAgent != null) return _userAgent!;

      final db = GetIt.I.get<DatabaseService>().database;
      final rowsRaw = await db.database.query(
        xmppStateTable,
        where: 'key = ?',
        whereArgs: [_userAgentKey],
      );
      if (rowsRaw.isEmpty) {
        // Generate a new user agent
        _userAgent = UserAgent(
          software: 'Moxxy',
          id: const Uuid().v4(),
        );

        // Write it to the database
        await db.insert(
          xmppStateTable,
          {
            'key': _userAgentKey,
            'value': jsonEncode(_userAgent!.toJson()),
          },
        );

        return _userAgent!;
      }

      assert(rowsRaw.length == 1, 'Only one row must exist');

      final data = rowsRaw.first['value']! as String;
      final json =
          (jsonDecode(data) as Map<dynamic, dynamic>).cast<String, String?>();
      final userAgent = UserAgent(
        device: json['device'],
        software: json['software'],
        id: json['id'],
      );
      _userAgent = userAgent;
      return _userAgent!;
    });
  }

  Future<XmppState> getXmppState() async {
    if (_state != null) return _state!;

    final json = <String, String?>{};
    final rowsRaw =
        await GetIt.I.get<DatabaseService>().database.query(xmppStateTable);
    for (final row in rowsRaw) {
      json[row['key']! as String] = row['value'] as String?;
    }

    _state = XmppState.fromDatabaseTuples(json);
    return _state!;
  }

  /// A wrapper to modify the [XmppState] and commit it.
  Future<void> modifyXmppState(XmppState Function(XmppState) func) async {
    _state = func(_state!);

    final batch = GetIt.I.get<DatabaseService>().database.batch();
    for (final tuple in _state!.toDatabaseTuples().entries) {
      batch.insert(
        xmppStateTable,
        <String, String?>{'key': tuple.key, 'value': tuple.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  /// Resets the current account JID to null.
  Future<void> resetAccountJid() async {
    _accountJid = null;
    await _storage.delete(key: _accountJidKey);
  }

  /// Sets the current account JID to [jid] and stores it in the secure storage.
  Future<void> setAccountJid(String jid) async {
    _accountJid = jid;
    await _storage.write(key: _accountJidKey, value: jid);
  }

  Future<String?> _loadAccountJid() async {
    return _accountJid ??= await _storage.read(key: _accountJidKey);
  }

  /// Returns a string if we have an account jid and null if we don't.
  Future<String?> getRawAccountJid() async {
    if (_accountJid != null) {
      return _accountJid;
    }

    return _loadAccountJid();
  }

  /// Gets the current account JID from the cache or from the secure storage.
  Future<String> getAccountJid() async {
    return _accountJid ?? (await _loadAccountJid())!;
  }
}
