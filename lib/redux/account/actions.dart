import "package:moxxyv2/redux/account/state.dart";

class SetDisplayNameAction {
  final String displayName;

  SetDisplayNameAction({ required this.displayName });
}

class SetAvatarAction {
  final String avatarUrl;

  SetAvatarAction({ required this.avatarUrl });
}

class SetJidAction {
  final String jid;

  SetJidAction({ required this.jid });
}

class SetAccountAction {
  final AccountState state;

  SetAccountAction({ required this.state });
}

class PerformLogoutAction {}
