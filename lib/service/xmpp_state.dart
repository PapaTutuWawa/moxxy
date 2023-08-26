import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/xmpp.dart';
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
  late XmppState _state;
  final Lock _stateLock = Lock();
  Future<XmppState> get state => _stateLock.synchronized(() => _state);

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
            'accountJid': _accountJid,
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

  Future<void> initializeXmppState() async {
    // NOTE: Called only once at the start so we don't have to worry about aquiring a lock
    final state = await _loadXmppState(_accountJid);
    if (_accountJid == null || state == null) {
      _log.finest(
        'No account JID or account state available. Creating default value',
      );
      _state = XmppState(jid: _accountJid);
      return;
    }

    _state = state;
  }

  Future<XmppState?> _loadXmppState(String? accountJid) async {
    if (accountJid == null) {
      return null;
    }

    final json = <String, String?>{};
    final rowsRaw = await GetIt.I.get<DatabaseService>().database.query(
      xmppStateTable,
      where: 'accountJid = ?',
      whereArgs: [accountJid],
      columns: ['key', 'value'],
    );
    if (rowsRaw.isEmpty) {
      return null;
    }

    for (final row in rowsRaw) {
      json[row['key']! as String] = row['value'] as String?;
    }

    return XmppState.fromDatabaseTuples(json);
  }

  /// The same as [commitXmppState] but without aquiring [_stateLock].
  Future<void> _commitXmppState(String accountJid) async {
    final batch = GetIt.I.get<DatabaseService>().database.batch();
    for (final tuple in _state.toDatabaseTuples().entries) {
      batch.insert(
        xmppStateTable,
        <String, String?>{
          'key': tuple.key,
          'value': tuple.value,
          'accountJid': accountJid
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<void> commitXmppState(String accountJid) async {
    await _stateLock.synchronized(
      () => _commitXmppState(accountJid),
    );
  }

  Future<void> setXmppState(XmppState state, String accountJid) async {
    await _stateLock.synchronized(
      () async {
        _state = state;
        await _commitXmppState(accountJid);
      },
    );
  }

  /// A wrapper to modify the [XmppState] and commit it.
  Future<void> modifyXmppState(
    XmppState Function(XmppState) func, {
    bool commit = true,
  }) async {
    final accountJid = await getAccountJid();
    assert(
      accountJid != null,
      'The accountJid must be not empty',
    );

    await _stateLock.synchronized(
      () async {
        _state = func(_state);

        if (commit) {
          await _commitXmppState(accountJid!);
        }
      },
    );
  }

  /// Resets the current account JID to null.
  Future<void> resetAccountJid() async {
    _accountJid = null;
    await _storage.delete(key: _accountJidKey);
  }

  /// Sets the current account JID to [jid] and stores it in the secure storage.
  Future<void> setAccountJid(String jid, {bool commit = true}) async {
    _accountJid = jid;

    if (commit) {
      await _storage.write(key: _accountJidKey, value: jid);
    }
  }

  Future<String?> _loadAccountJid() async {
    return _accountJid ??= await _storage.read(key: _accountJidKey);
  }

  /// Gets the current account JID from the cache or from the secure storage.
  Future<String?> getAccountJid() async {
    return _accountJid ?? await _loadAccountJid();
  }

  Future<bool> isLoggedIn(String? accountJid) async {
    final s = await state;
    if (accountJid == null || s.jid == null || s.password == null) {
      return false;
    }

    return await GetIt.I.get<XmppService>().getConnectionSettings() != null;
  }
}
