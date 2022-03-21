import "package:moxxyv2/shared/models/conversation.dart";

class ProfilePageArguments {
  final Conversation? conversation;
  final bool isSelfProfile;

  ProfilePageArguments({ this.conversation, required this.isSelfProfile }) {
    assert(isSelfProfile ? true : conversation != null);
  }
}
