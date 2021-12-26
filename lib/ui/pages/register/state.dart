class RegisterPageState {
  final int providerIndex;
  final bool doingWork;
  final String? errorText;

  RegisterPageState({ required this.providerIndex, required this.doingWork, this.errorText });

  RegisterPageState copyWith({ int? providerIndex, bool? doingWork, String? errorText }) {
    return RegisterPageState(
      providerIndex: providerIndex ?? this.providerIndex,
      doingWork: doingWork ?? this.doingWork,
      errorText: errorText
    );
  }
}
