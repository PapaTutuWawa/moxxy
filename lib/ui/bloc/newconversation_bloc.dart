import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/ui/bloc/conversations_bloc.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";

import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:get_it/get_it.dart";

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
    final conversations = GetIt.I.get<ConversationsBloc>();

    // Guard against an unneccessary roundtrip
    if (listContains(conversations.state.conversations, (Conversation c) => c.jid == event.jid)) {
      // TODO: Redirect
      return;
    }

    final result = await GetIt.I.get<BackgroundServiceDataSender>().sendData(
      AddConversationCommand(
        title: event.title,
        jid: event.jid,
        avatarUrl: event.avatarUrl,
        lastMessageBody: ""
      )
    );
    
    if (result is NoConversationModifiedEvent) {
      // TODO: Just redirect
    } else if (result is ConversationUpdatedEvent) {
      conversations.add(ConversationsUpdatedEvent(result.conversation));
      // TODO: Redirect
    } else if (result is ConversationAddedEvent) {
      conversations.add(ConversationsAddedEvent(result.conversation));
      // TODO: Redirect
    }
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
