part of "profile_bloc.dart";

abstract class ProfileEvent {}

/// Triggered when a navigation to a profile page is requested
class ProfilePageRequestedEvent extends ProfileEvent {
  final bool isSelfProfile;
  final Conversation? conversation;
  final String? jid;
  final String? avatarUrl;
  final String? displayName;

  ProfilePageRequestedEvent(
    this.isSelfProfile,
    {
      this.conversation,
      this.jid,
      this.avatarUrl,
      this.displayName
    }
  );
}

/// Triggered when a conversation is updated
class ConversationUpdatedEvent extends ProfileEvent {
  final Conversation conversation;

  ConversationUpdatedEvent(this.conversation);
}
