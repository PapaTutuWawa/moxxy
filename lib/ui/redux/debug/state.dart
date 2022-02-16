class DebugState {
  final bool enabled;
  final String ip;
  final int port;
  final String passphrase;

  const DebugState({ required this.enabled, required this.ip, required this.port, required this.passphrase });
  const DebugState.initialState(): enabled = false, ip = "", port = 0, passphrase = "";

  DebugState copyWith({ bool? enabled, String? ip, int? port, String? passphrase }) {
    return DebugState(
      enabled: enabled ?? this.enabled,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      passphrase: passphrase ?? this.passphrase
    );
  }
}
