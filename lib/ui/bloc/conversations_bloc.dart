import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';

part 'conversations_bloc.freezed.dart';
part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc() : super(ConversationsState()) {
    on<ConversationsInitEvent>(_onInit);
    on<ConversationsAddedEvent>(_onConversationsAdded);
    on<ConversationsUpdatedEvent>(_onConversationsUpdated);
    on<AvatarChangedEvent>(_onAvatarChanged);
    on<ConversationClosedEvent>(_onConversationClosed);
  }

  Future<void> _onInit(ConversationsInitEvent event, Emitter<ConversationsState> emit) async {
    return emit(
      state.copyWith(
        displayName: event.displayName,
        jid: event.jid,
        avatarUrl: event.avatarUrl ?? '',
        conversations: event.conversations..sort(compareConversation),
      ),
    );
  }

  Future<void> _onConversationsAdded(ConversationsAddedEvent event, Emitter<ConversationsState> emit) async {
    // TODO(Unknown): Should we guard against adding the same conversation multiple times?
    return emit(
      state.copyWith(
        conversations: List.from(<Conversation>[ ...state.conversations, event.conversation ])
          ..sort(compareConversation),
      ),
    );
  }

  Future<void> _onConversationsUpdated(ConversationsUpdatedEvent event, Emitter<ConversationsState> emit) async {
    return emit(
      state.copyWith(
        conversations: List.from(state.conversations.map((c) {
            if (c.jid == event.conversation.jid) return event.conversation;

            return c;
        }).toList()..sort(compareConversation),),
      ),
    );
  }

  Future<void> _onAvatarChanged(AvatarChangedEvent event, Emitter<ConversationsState> emit) async {
    return emit(
      state.copyWith(
        avatarUrl: event.path,
      ),
    );
  }

  Future<void> _onConversationClosed(ConversationClosedEvent event, Emitter<ConversationsState> emit) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
      CloseConversationCommand(jid: event.jid),
    );

    emit(
      state.copyWith(
        conversations: state.conversations.where((c) => c.jid != event.jid).toList(),
      ),
    );
  }
}
