import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';

part 'profile_bloc.freezed.dart';
part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileState()) {
    on<ProfilePageRequestedEvent>(_onProfileRequested);
    on<ConversationUpdatedEvent>(_onConversationUpdated);
    on<AvatarSetEvent>(_onAvatarSet);
    on<SetSubscriptionStateEvent>(_onSetSubscriptionState);
    on<MuteStateSetEvent>(_onMuteStateSet);
  }

  Future<void> _onProfileRequested(
    ProfilePageRequestedEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (event.isSelfProfile) {
      emit(
        state.copyWith(
          jid: event.jid!,
          avatarUrl: event.avatarUrl!,
          displayName: event.displayName!,
        ),
      );
    } else {
      emit(
        state.copyWith(
          conversation: event.conversation,
        ),
      );
    }

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            NavigationDestination(
              profileRoute,
              arguments: ProfileArguments(
                event.isSelfProfile,
                event.jid ?? event.conversation!.jid,
                event.conversation?.type ?? ConversationType.chat,
              ),
            ),
          ),
        );
  }

  Future<void> _onConversationUpdated(
    ConversationUpdatedEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.conversation == null ||
        state.conversation!.jid != event.conversation.jid) return;

    emit(state.copyWith(conversation: event.conversation));
  }

  Future<void> _onAvatarSet(
    AvatarSetEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        avatarUrl: event.path,
      ),
    );

    GetIt.I.get<ConversationsBloc>().add(AvatarChangedEvent(event.path));

    await getForegroundService().send(
      SetAvatarCommand(
        path: event.path,
        hash: event.hash,
      ),
      awaitable: false,
    );
  }

  Future<void> _onSetSubscriptionState(
    SetSubscriptionStateEvent event,
    Emitter<ProfileState> emit,
  ) async {
    await getForegroundService().send(
      SetShareOnlineStatusCommand(jid: event.jid, share: event.shareStatus),
      awaitable: false,
    );
  }

  Future<void> _onMuteStateSet(
    MuteStateSetEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          muted: event.muted,
        ),
      ),
    );
    await getForegroundService().send(
      SetConversationMuteStatusCommand(jid: event.jid, muted: event.muted),
      awaitable: false,
    );
  }
}
