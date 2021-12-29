class RegisterPageState {
  final int providerIndex;
  final String? errorText;

  RegisterPageState({ required this.providerIndex, this.errorText });

  RegisterPageState copyWith({ int? providerIndex, String? errorText }) {
    return RegisterPageState(
      providerIndex: providerIndex ?? this.providerIndex,
      errorText: errorText
    );
  }
}
