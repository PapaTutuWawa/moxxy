import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/xmpp_state.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class XmppStateService {
  /// Persistent state around the connection, like the SM token, etc.
  XmppState? _state;

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
}
