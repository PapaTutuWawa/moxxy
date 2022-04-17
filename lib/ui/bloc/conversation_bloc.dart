import "dart:async";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart" as events;
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";
import "package:moxxyv2/ui/bloc/conversations_bloc.dart";
import "package:moxxyv2/ui/bloc/sharedmedia_bloc.dart";
import "package:moxxyv2/xmpp/xeps/xep_0085.dart";

import "package:get_it/get_it.dart";
import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:flutter/widgets.dart";

part "conversation_state.dart";
part "conversation_event.dart";
part "conversation_bloc.freezed.dart";

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  /// The current chat state with the conversation partner
  ChatState _currentChatState;
  /// Timer to be able to send <paused /> notifications
  Timer? _composeTimer;
  /// The last time the text has been changed
  int _lastChangeTimestamp;

  ConversationBloc()
    : _currentChatState = ChatState.gone,
      _lastChangeTimestamp = 0,
      super(ConversationState()) {
    on<RequestedConversationEvent>(_onRequestedConversation);
    on<MessageTextChangedEvent>(_onMessageTextChanged);
    on<InitConversationEvent>(_onInit);
    on<MessageSentEvent>(_onMessageSent);
    on<MessageQuotedEvent>(_onMessageQuoted);
    on<QuoteRemovedEvent>(_onQuoteRemoved);
    on<JidBlockedEvent>(_onJidBlocked);
    on<JidAddedEvent>(_onJidAdded);
    on<CurrentConversationResetEvent>(_onCurrentConversationReset);
    on<MessageAddedEvent>(_onMessageAdded);
    on<MessageUpdatedEvent>(_onMessageUpdated);
    on<ConversationUpdatedEvent>(_onConversationUpdated);
    on<AppStateChanged>(_onAppStateChanged);
    on<BackgroundChangedEvent>(_onBackgroundChanged);
  }

  void _setLastChangeTimestamp() {
    _lastChangeTimestamp = DateTime.now().millisecondsSinceEpoch;
  }
  
  void _startComposeTimer() {
    if (_composeTimer != null) return;

    _composeTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastChangeTimestamp >= 3000) {
          // No change since 5 seconds
          _updateChatState(ChatState.paused);
          _stopComposeTimer();
        }
      }
    );
  }

  void _stopComposeTimer() {
    if (_composeTimer == null) return;

    _composeTimer!.cancel();
    _composeTimer = null;
  }
  
  bool _isSameConversation(String jid) => jid == state.conversation?.jid;
  
  /// Returns true if [msg] is meant for the open conversation. False otherwise.
  bool _isMessageForConversation(Message msg) => msg.conversationJid == state.conversation?.jid;

  /// Updates the local chat state and sends a chat state notification to the conversation
  /// partner.
  void _updateChatState(ChatState s) {
    if (s == _currentChatState) return;

    _currentChatState = s;
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SendChatStateCommand(
        state: s.toString().split(".").last,
        jid: state.conversation!.jid
      ),
      awaitable: false);
  }
  
  Future<void> _onInit(InitConversationEvent event, Emitter<ConversationState> emit) async {
    emit(
      state.copyWith(backgroundPath: event.backgroundPath)
    );
  }
  
  Future<void> _onRequestedConversation(RequestedConversationEvent event, Emitter<ConversationState> emit) async {
    final conversation = firstWhereOrNull(
      GetIt.I.get<ConversationsBloc>().state.conversations,
      (Conversation c) => c.jid == event.jid
    )!;
    emit(
      state.copyWith(
        conversation: conversation
      )
    );

    _updateChatState(ChatState.active);

    final navEvent = event.removeUntilConversations ? (
      PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(conversationRoute),
        ModalRoute.withName(conversationsRoute)
      )
    ) : (
      PushedNamedEvent(
        const NavigationDestination(conversationRoute)
      )
    );
    
    GetIt.I.get<NavigationBloc>().add(navEvent);

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
    GetIt.I.get<SharedMediaBloc>().add(
      SetSharedMedia(
        conversation.title,
        conversation.jid,
        conversation.sharedMedia
      )
    );
  }

  Future<void> _onMessageTextChanged(MessageTextChangedEvent event, Emitter<ConversationState> emit) async {
    
    _setLastChangeTimestamp();
    _startComposeTimer();
    _updateChatState(ChatState.composing);

    return emit(
      state.copyWith(
        messageText: event.value,
        showSendButton: event.value.isNotEmpty
      )
    );
  }

  Future<void> _onMessageSent(MessageSentEvent event, Emitter<ConversationState> emit) async {
    // Set it but don't notify
    _currentChatState = ChatState.active;
    _stopComposeTimer();
    
    final result = await GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SendMessageCommand(
        jid: state.conversation!.jid,
        body: state.messageText,
        quotedMessage: state.quotedMessage,
        chatState: chatStateToString(ChatState.active)
      )
    ) as events.MessageAddedEvent;

    emit(
      state.copyWith(
        messages: List.from([ ...state.messages, result.message ]),
        messageText: "",
        quotedMessage: null,
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
      AddContactCommand(jid: state.conversation!.jid)
    );
  }

  Future<void> _onCurrentConversationReset(CurrentConversationResetEvent event, Emitter<ConversationState> emit) async {
    _updateChatState(ChatState.gone);

    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SetOpenConversationCommand(jid: null),
      awaitable: false
    );
  }

  Future<void> _onMessageAdded(MessageAddedEvent event, Emitter<ConversationState> emit) async {
    if (!_isMessageForConversation(event.message)) return;

    emit(
      state.copyWith(
        messages: List.from([ ...state.messages, event.message ]),
      )
    );
  }

  Future<void> _onMessageUpdated(MessageUpdatedEvent event, Emitter<ConversationState> emit) async {
    if (!_isMessageForConversation(event.message)) return;

    // TODO: Check if we are iterating the correct wa
    // Small trick: The newer messages are much more likely to be updated than
    // older messages.
    /*
    final messages = state.messages;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].id == event.message.id) {
        print("Found message to update");
        messages[i] = event.message;
        break;
      }
    }
    */
    
    // We don't have to re-sort the list here as timestamps never change
    emit(
      state.copyWith(
        messages: List.from(state.messages.map((m) {
              if (m.id == event.message.id) return event.message;

              return m;
        })),
      )
    );
  }

  Future<void> _onConversationUpdated(ConversationUpdatedEvent event, Emitter<ConversationState> emit) async {
    if (!_isSameConversation(event.conversation.jid)) return;

    emit(state.copyWith(conversation: event.conversation));
  }

  Future<void> _onAppStateChanged(AppStateChanged event, Emitter<ConversationState> emit) async {
    if (state.conversation == null) return;

    if (event.open) {
      _updateChatState(ChatState.active);
    } else {
      _stopComposeTimer();
      _updateChatState(ChatState.gone);
    }
  }

  Future<void> _onBackgroundChanged(BackgroundChangedEvent event, Emitter<ConversationState> emit) async {
    return emit(state.copyWith(backgroundPath: event.backgroundPath));
  }
}
