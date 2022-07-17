import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";
import "package:moxxyv2/ui/bloc/conversations_bloc.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:get_it/get_it.dart";
import "package:moxplatform/moxplatform.dart";

part "profile_state.dart";
part "profile_event.dart";
part "profile_bloc.freezed.dart";

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileState()) {
    on<ProfilePageRequestedEvent>(_onProfileRequested);
    on<ConversationUpdatedEvent>(_onConversationUpdated);
    on<AvatarSetEvent>(_onAvatarSet);
    on<SetSubscriptionStateEvent>(_onSetSubscriptionState);
  }

  Future<void> _onProfileRequested(ProfilePageRequestedEvent event, Emitter<ProfileState> emit) async {
    if (event.isSelfProfile) {
      emit(
        state.copyWith(
          isSelfProfile: true,
          jid: event.jid!,
          avatarUrl: event.avatarUrl!,
          displayName: event.displayName!
        )
      );
    } else {
      emit(
        state.copyWith(
          isSelfProfile: false,
          conversation: event.conversation!
        )
      );
    }

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(
          profileRoute
        )
      )
    );

    if (event.isSelfProfile) {
      final result = await MoxplatformPlugin.handler.getDataSender().sendData(
        GetFeaturesCommand()
      ) as GetFeaturesEvent;

      emit(
        state.copyWith(
          serverFeatures: result.serverFeatures,
          streamManagementSupported: result.supportsStreamManagement,
        )
      );
    }
  }

  Future<void> _onConversationUpdated(ConversationUpdatedEvent event, Emitter<ProfileState> emit) async {
    if (state.conversation == null || state.conversation!.jid != event.conversation.jid) return;

    emit(state.copyWith(conversation: event.conversation));
  }

  Future<void> _onAvatarSet(AvatarSetEvent event, Emitter<ProfileState> emit) async {
    emit(
      state.copyWith(
        avatarUrl: event.path
      )
    );

    GetIt.I.get<ConversationsBloc>().add(AvatarChangedEvent(event.path));
    
    MoxplatformPlugin.handler.getDataSender().sendData(
      SetAvatarCommand(
        path: event.path,
        hash: event.hash
      ),
      awaitable: false
    );
  }

  Future<void> _onSetSubscriptionState(SetSubscriptionStateEvent event, Emitter<ProfileState> emit) async {
    // TODO: Maybe already emit the state change to have it instant and debounce it until
    //       everything else is done
    MoxplatformPlugin.handler.getDataSender().sendData(
      SetShareOnlineStatusCommand(jid: event.jid, share: event.shareStatus),
      awaitable: false
    );
  }
}
