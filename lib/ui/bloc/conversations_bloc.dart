import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:synchronized/synchronized.dart';

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
    on<ConversationMarkedAsReadEvent>(_onConversationMarkedAsRead);
    on<ConversationsSetEvent>(_onConversationsSet);
    on<ConversationExitedEvent>(_onConversationExited);
  }

  // TODO(Unknown): This pattern is used so often that it should become its own thing in moxlib
  bool _initialized = false;
  final Lock _lock = Lock();
  final List<Completer<void>> _completers = List.empty(growable: true);

  /// Asynchronously blocks until a ConversationsInitEvent has been triggered and
  /// processed. Useful to ensure that accessing the BLoC's state outside of
  /// a BlocBuilder causes a NPE.
  Future<void> waitUntilInitialized() async {
    final comp = await _lock.synchronized(() {
      if (!_initialized) {
        final completer = Completer<void>();
        _completers.add(completer);
        return completer;
      }

      return null;
    });

    if (comp != null) await comp.future;
  }

  Future<void> _onInit(
    ConversationsInitEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(
      state.copyWith(
        displayName: event.displayName,
        jid: event.jid,
        avatarPath: event.avatarUrl ?? '',
        conversations: event.conversations..sort(compareConversation),
      ),
    );

    await _lock.synchronized(() {
      _initialized = true;

      for (final completer in _completers) {
        completer.complete();
      }

      _completers.clear();
    });
  }

  Future<void> _onConversationExited(
    ConversationExitedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          ExitConversationCommand(
            conversationType: event.type.value,
          ),
          awaitable: false,
        );
  }

  Future<void> _onConversationsAdded(
    ConversationsAddedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    // TODO(Unknown): Should we guard against adding the same conversation multiple times?
    emit(
      state.copyWith(
        conversations: List.from(
          <Conversation>[...state.conversations, event.conversation]
            ..sort(compareConversation),
        ),
      ),
    );

    // TODO(Unknown): Doing it from here feels absolutely not clean. Maybe change that.
    GetIt.I.get<ShareSelectionBloc>().add(
          ConversationsModified(state.conversations),
        );
  }

  Future<void> _onConversationsUpdated(
    ConversationsUpdatedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(
      state.copyWith(
        conversations: List.from(
          state.conversations.map((c) {
            if (c.jid == event.conversation.jid) return event.conversation;

            return c;
          }).toList()
            ..sort(compareConversation),
        ),
      ),
    );

    // TODO(Unknown): Doing it from here feels absolutely not clean. Maybe change that.
    GetIt.I.get<ShareSelectionBloc>().add(
          ConversationsModified(state.conversations),
        );
  }

  Future<void> _onAvatarChanged(
    AvatarChangedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    return emit(
      state.copyWith(
        avatarPath: event.path,
      ),
    );
  }

  Future<void> _onConversationClosed(
    ConversationClosedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          CloseConversationCommand(jid: event.jid),
        );

    emit(
      state.copyWith(
        conversations:
            state.conversations.where((c) => c.jid != event.jid).toList(),
      ),
    );
  }

  Future<void> _onConversationMarkedAsRead(
    ConversationMarkedAsReadEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          MarkConversationAsReadCommand(conversationJid: event.jid),
          awaitable: false,
        );
  }

  /// Return, if existent, the conversation from the state with a JID equal to [jid].
  /// Returns null, if the conversation does not exist.
  Conversation? getConversationByJid(String jid) {
    return state.conversations.firstWhereOrNull((c) => c.jid == jid);
  }

  Future<void> _onConversationsSet(
    ConversationsSetEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(
      state.copyWith(
        conversations: event.conversations,
      ),
    );
  }
}
