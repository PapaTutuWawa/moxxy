import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/models/roster.dart";
//import "package:moxxyv2/shared/backgroundsender.dart";

import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "newconversation_state.dart";
part "newconversation_event.dart";
part "newconversation_bloc.freezed.dart";

class NewConversationBloc extends Bloc<NewConversationEvent, NewConversationState> {
  NewConversationBloc() : super(NewConversationState()) {
    on<NewConversationInitEvent>(_onInit);
    on<NewConversationAddedEvent>(_onAdded);
    on<NewConversationRosterItemRemovedEvent>(_onRosterItemRemoved);
  }

  Future<void> _onInit(NewConversationInitEvent event, Emitter<NewConversationState> emit) async {
    return emit(
      state.copyWith(
        roster: event.roster
      )
    );
  }

  Future<void> _onAdded(NewConversationAddedEvent event, Emitter<NewConversationState> emit) async {
    // TODO
  }

  Future<void> _onRosterItemRemoved(NewConversationRosterItemRemovedEvent event, Emitter<NewConversationState> emit) async {
    // TODO
    return emit(
      state.copyWith(
        roster: state.roster.where(
          (item) => item.jid != event.jid
        ).toList()
      )
    );
  }
}
