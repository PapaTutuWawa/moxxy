class ConversationPageState {
  final bool showSendButton;

  ConversationPageState({ required this.showSendButton });

  ConversationPageState copyWith({ bool? showSendButton }) {
    return ConversationPageState(
      showSendButton: showSendButton ?? this.showSendButton
    );
  }
}
