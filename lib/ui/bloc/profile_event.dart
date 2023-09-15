part of 'profile_bloc.dart';

abstract class ProfileEvent {}

/// Triggered when a navigation to a profile page is requested
class ProfilePageRequestedEvent extends ProfileEvent {
  ProfilePageRequestedEvent(
    this.isSelfProfile, {
    this.conversation,
    this.jid,
    this.avatarUrl,
    this.displayName,
  });
  final bool isSelfProfile;
  final Conversation? conversation;
  final String? jid;
  final String? avatarUrl;
  final String? displayName;
}

/// Triggered when a conversation is updated
class ConversationUpdatedEvent extends ProfileEvent {
  ConversationUpdatedEvent(this.conversation);

  final Conversation conversation;
}

/// Triggered by the UI when a new avatar has been set
class AvatarSetEvent extends ProfileEvent {
  AvatarSetEvent(this.path, this.hash, this.userTriggered);

  final String path;
  final String hash;
  final bool userTriggered;
}

/// Triggered by the UI when the subscription state should be set
class SetSubscriptionStateEvent extends ProfileEvent {
  SetSubscriptionStateEvent(this.jid, this.shareStatus);

  final String jid;
  final bool shareStatus;
}

/// Triggered by the UI when we change the mute status of a chat
class MuteStateSetEvent extends ProfileEvent {
  MuteStateSetEvent(this.jid, this.muted);

  final String jid;
  final bool muted;
}
