import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:get_it/get_it.dart";

part "profile_state.dart";
part "profile_event.dart";
part "profile_bloc.freezed.dart";

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileState()) {
    on<ProfilePageRequestedEvent>(_onProfileRequested);
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
        NavigationDestination(
          profileRoute
        )
      )
    );
  }
}
