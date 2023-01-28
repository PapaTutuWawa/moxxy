import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/xmpp_state.dart';

class XmppStateService {
  /// Persistent state around the connection, like the SM token, etc.
  XmppState? _state;

  Future<XmppState> getXmppState() async {
    if (_state != null) return _state!;

    _state = await GetIt.I.get<DatabaseService>().getXmppState();
    return _state!;
  }

  /// A wrapper to modify the [XmppState] and commit it.
  Future<void> modifyXmppState(XmppState Function(XmppState) func) async {
    _state = func(_state!);
    await GetIt.I.get<DatabaseService>().saveXmppState(_state!);
  }
}
