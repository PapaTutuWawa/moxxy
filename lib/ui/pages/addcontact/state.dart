class AddContactPageState {
  final bool doingWork;

  AddContactPageState({ required this.doingWork });

  AddContactPageState copyWith({ bool? doingWork }) {
    return AddContactPageState(
      doingWork: doingWork ?? this.doingWork
    );
  }
}
