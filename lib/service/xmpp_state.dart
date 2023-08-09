import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/xmpp_state.dart';
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

class XmppStateService {
  /// Persistent state around the connection, like the SM token, etc.
  XmppState? _state;

  /// Cache the user agent
  UserAgent? _userAgent;
  final Lock _userAgentLock = Lock();

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

  Future<String> getAccountJid() async {
    // TODO:
    return '';
  }
}
