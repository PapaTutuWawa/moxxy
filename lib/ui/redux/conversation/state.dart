import "package:moxxyv2/shared/models/message.dart";

class ConversationPageState {
  final bool showSendButton;
  final bool showScrollToEndButton;
  final Message? quotedMessage;

  ConversationPageState({
      required this.showSendButton,
      required this.showScrollToEndButton,
      this.quotedMessage
  });
  ConversationPageState.initialState() : showSendButton = false, showScrollToEndButton = false, quotedMessage = null;

  ConversationPageState copyWith(Message? quotedMessage, { bool? showSendButton, bool? showScrollToEndButton }) {
    return ConversationPageState(
      showSendButton: showSendButton ?? this.showSendButton,
      showScrollToEndButton: showScrollToEndButton ?? this.showScrollToEndButton,
      quotedMessage: quotedMessage
    );
  }
}
