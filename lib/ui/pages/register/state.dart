class RegisterPageState {
  final int providerIndex;
  final bool doingWork;

  RegisterPageState({ required this.providerIndex, required this.doingWork });

  RegisterPageState copyWith({ int? providerIndex, bool? doingWork }) {
    return RegisterPageState(
      providerIndex: providerIndex ?? this.providerIndex,
      doingWork: doingWork ?? this.doingWork
    );
  }
}
