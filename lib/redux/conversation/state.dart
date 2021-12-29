class ConversationPageState {
  final bool showSendButton;
  final bool showScrollToEndButton;

  ConversationPageState({ required this.showSendButton, required this.showScrollToEndButton });

  ConversationPageState copyWith({ bool? showSendButton, bool? showScrollToEndButton }) {
    return ConversationPageState(
      showSendButton: showSendButton ?? this.showSendButton,
      showScrollToEndButton: showScrollToEndButton ?? this.showScrollToEndButton
    );
  }
}
