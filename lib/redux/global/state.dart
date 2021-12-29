class GlobalState {
  final bool doingWork;

  GlobalState({ required this.doingWork });
  GlobalState.initialState() : doingWork = false;

  GlobalState copyWith({ bool? doingWork }) {
    return GlobalState(
      doingWork: doingWork ?? this.doingWork
    );
  }
}
