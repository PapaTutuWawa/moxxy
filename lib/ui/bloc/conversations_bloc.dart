import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:get_it/get_it.dart";
import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "conversations_state.dart";
part "conversations_event.dart";
part "conversations_bloc.freezed.dart";

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc() : super(ConversationsState()) {
    on<ConversationsInitEvent>(_onLoggedIn);
  }

  Future<void> _onLoggedIn(ConversationsInitEvent event, Emitter<ConversationsState> emit) async {
    return emit(
      state.copyWith(
        displayName: event.displayName
      )
    );
  }
}
