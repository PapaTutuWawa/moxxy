class ProfilePageState {
  final bool showSnackbar;

  ProfilePageState({ required this.showSnackbar });
  ProfilePageState.initialState() : showSnackbar = false;

  ProfilePageState copyWith({ bool? showSnackbar }) {
    return ProfilePageState(
      showSnackbar: showSnackbar ?? this.showSnackbar
    );
  }
}
