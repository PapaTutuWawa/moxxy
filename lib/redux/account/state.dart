class AccountState {
  final String jid;
  final String displayName;
  final String avatarUrl;

  AccountState({ required this.jid, required this.displayName, required this.avatarUrl });

  AccountState copyWith({ String? jid, String? displayName, String? avatarUrl }) {
    return AccountState(
      jid: jid ?? this.jid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
