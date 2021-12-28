import "package:hive/hive.dart";
import "package:redux/redux.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/account/actions.dart";

class AccountRepository {
  final Store<MoxxyState> store;

  AccountRepository({ required this.store });

  void loadSettings() async {
    var box = await Hive.openBox("account");

    if (box.isNotEmpty) {
      String? jid = await box.get("jid");
      String? displayName = await box.get("displayName");
      String? avatarUrl = await box.get("avatarUrl");

      this.store.dispatch(SetDisplayNameAction(displayName: displayName!));
      this.store.dispatch(SetAvatarAction(avatarUrl: avatarUrl!));
      this.store.dispatch(SetJidAction(jid: jid!));
      this.store.dispatch(NavigateToAction.replace("/conversations"));
    } else {
      this.store.dispatch(NavigateToAction.replace("/intro"));
    }
  }
}
