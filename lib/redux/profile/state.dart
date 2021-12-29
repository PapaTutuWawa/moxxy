class ProfilePageState {
  final bool showSnackbar;

  ProfilePageState({ required this.showSnackbar });

  ProfilePageState copyWith({ bool? showSnackbar }) {
    return ProfilePageState(
      showSnackbar: showSnackbar ?? this.showSnackbar
    );
  }
}
