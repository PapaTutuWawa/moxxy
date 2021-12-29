class GlobalState {
  final bool doingWork;

  GlobalState({ required this.doingWork });

  GlobalState copyWith({ bool? doingWork }) {
    return GlobalState(
      doingWork: doingWork ?? this.doingWork
    );
  }
}
