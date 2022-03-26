import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "conversations_state.dart";
part "conversations_event.dart";
part "conversations_bloc.freezed.dart";

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc() : super(ConversationsState()) {
    on<ConversationsInitEvent>(_onInit);
    on<ConversationsAddedEvent>(_onConversationsAdded);
    on<ConversationsUpdatedEvent>(_onConversationsUpdated);
  }

  Future<void> _onInit(ConversationsInitEvent event, Emitter<ConversationsState> emit) async {
    return emit(
      state.copyWith(
        displayName: event.displayName,
        jid: event.jid,
        conversations: event.conversations..sort(compareConversation)
      )
    );
  }

  Future<void> _onConversationsAdded(ConversationsAddedEvent event, Emitter<ConversationsState> emit) async {
    // TODO: Should we guard against adding the same conversation multiple times?
    return emit(
      state.copyWith(
        conversations: List.from([ ...state.conversations, event.conversation ])..sort(compareConversation)
      )
    );
  }

  Future<void> _onConversationsUpdated(ConversationsUpdatedEvent event, Emitter<ConversationsState> emit) async {
    return emit(
      state.copyWith(
        conversations: List.from(state.conversations.map((c) {
            if (c.jid == event.conversation.jid) return event.conversation;

            return c;
        }).toList()..sort(compareConversation))
      )
    );
  }
}
