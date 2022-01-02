import "dart:collection";

import "package:moxxyv2/models/conversation.dart";

// TODO: Move to lib/redux/conversation
class AddConversationAction {
  Conversation conversation;

  AddConversationAction({ required this.conversation });
}

// TODO: Move to lib/redux/conversation
class AddMultipleConversationsAction {
  List<Conversation> conversations;

  AddMultipleConversationsAction({ required this.conversations });
}

// TODO: Move to lib/redux/conversation
class UpdateConversationAction {
  Conversation conversation;

  UpdateConversationAction({ required this.conversation });
}
