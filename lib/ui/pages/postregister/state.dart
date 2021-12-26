class PostRegisterPageState {
  final bool showSnackbar;

  PostRegisterPageState({ required this.showSnackbar });

  PostRegisterPageState copyWith({ bool? showSnackbar }) {
    return PostRegisterPageState(
      showSnackbar: showSnackbar ?? this.showSnackbar
    );
  }
}
