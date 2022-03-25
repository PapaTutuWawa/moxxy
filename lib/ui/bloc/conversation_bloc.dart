import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart" as events;
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";
import "package:moxxyv2/ui/bloc/conversations_bloc.dart";

import "package:get_it/get_it.dart";
import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "conversation_state.dart";
part "conversation_event.dart";
part "conversation_bloc.freezed.dart";

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc() : super(ConversationState()) {
    on<RequestedConversationEvent>(_onRequestedConversation);
    on<MessageTextChangedEvent>(_onMessageTextChanged);
    on<InitConversationEvent>(_onInit);
    on<MessageSentEvent>(_onMessageSent);
    on<MessageQuotedEvent>(_onMessageQuoted);
    on<QuoteRemovedEvent>(_onQuoteRemoved);
    on<JidBlockedEvent>(_onJidBlocked);
    on<JidAddedEvent>(_onJidAdded);
    on<CurrentConversationResetEvent>(_onCurrentConversationReset);
    on<MessageAddedEvent>(_onMessageAddedEvent);
  }

  Future<void> _onInit(InitConversationEvent event, Emitter<ConversationState> emit) async {
    emit(
      state.copyWith(backgroundPath: event.backgroundPath)
    );
  }
  
  Future<void> _onRequestedConversation(RequestedConversationEvent event, Emitter<ConversationState> emit) async {
    emit(
      state.copyWith(
        conversation: firstWhereOrNull(
          GetIt.I.get<ConversationsBloc>().state.conversations,
          (Conversation c) => c.jid == event.jid
        )
      )
    );

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(conversationRoute)
      )
    );

    final result = await GetIt.I.get<BackgroundServiceDataSender>().sendData(
      GetMessagesForJidCommand(
        jid: event.jid,
      )
    ) as events.MessagesResultEvent;
    emit(state.copyWith(messages: result.messages));

    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SetOpenConversationCommand(jid: event.jid),
      awaitable: false
    );
  }

  Future<void> _onMessageTextChanged(MessageTextChangedEvent event, Emitter<ConversationState> emit) async {
    return emit(
      state.copyWith(
        messageText: event.value,
        showSendButton: event.value.isNotEmpty
      )
    );
  }

  Future<void> _onMessageSent(MessageSentEvent event, Emitter<ConversationState> emit) async {
    final result = await GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SendMessageCommand(
        jid: state.conversation!.jid,
        body: state.messageText,
        quotedMessage: state.quotedMessage
      )
    ) as events.MessageAddedEvent;

    emit(
      state.copyWith(
        messages: List.from([ ...state.messages, result.message ]),
        messageText: "",
        showSendButton: false
      )
    );
  }

  Future<void> _onMessageQuoted(MessageQuotedEvent event, Emitter<ConversationState> emit) async {
    return emit(
      state.copyWith(
        quotedMessage: event.message
      )
    );
  }

  Future<void> _onQuoteRemoved(QuoteRemovedEvent event, Emitter<ConversationState> emit) async {
    return emit(
      state.copyWith(
        quotedMessage: null
      )
    );
  }

  Future<void> _onJidBlocked(JidBlockedEvent event, Emitter<ConversationState> emit) async {
    // TODO: Maybe have some state here
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      BlockJidCommand(jid: state.conversation!.jid)
    );
  }

  Future<void> _onJidAdded(JidAddedEvent event, Emitter<ConversationState> emit) async {
    // TODO: Maybe have some state here
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      UnblockJidCommand(jid: state.conversation!.jid)
    );
  }

  Future<void> _onCurrentConversationReset(CurrentConversationResetEvent event, Emitter<ConversationState> emit) async {
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SetOpenConversationCommand(jid: null),
      awaitable: false
    );
  }

  Future<void> _onMessageAddedEvent(MessageAddedEvent event, Emitter<ConversationState> emit) async {
    if (event.bareJid != state.conversation?.jid) return;

    emit(
      state.copyWith(
        messages: List.from([ ...state.messages, event.message ]),
      )
    );
  }
}
