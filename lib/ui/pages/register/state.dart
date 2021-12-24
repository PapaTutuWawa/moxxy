class RegisterPageState {
  final int providerIndex;

  RegisterPageState({ required this.providerIndex });

  RegisterPageState copyWith({ int? providerIndex }) {
    return RegisterPageState(
      providerIndex: providerIndex ?? this.providerIndex
    );
  }
}
