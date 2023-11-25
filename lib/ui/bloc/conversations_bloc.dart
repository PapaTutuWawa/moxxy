import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:synchronized/synchronized.dart';

part 'conversations_bloc.freezed.dart';
part 'conversations_event.dart';
part 'conversations_state.dart';

/// A BLoC that handles changes to the conversations list. This included adding
/// conversations, updating conversations, and handling different changes, like
/// closing a conversation.
// TODO: Move into a new file.
class ConversationsCubit extends Cubit<List<Conversation>> {
  ConversationsCubit() : super([]);

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

  /// Initialize the conversations list.
  Future<void> init(List<Conversation> conversations) async {
    emit(conversations);

    await _lock.synchronized(() {
      _initialized = true;

      for (final completer in _completers) {
        completer.complete();
      }

      _completers.clear();
    });
  }

  /// Add [conversation] to the state.
  Future<void> addConversation(Conversation conversation) async {
    emit(
      List.from(
        <Conversation>[...state, conversation]..sort(compareConversation),
      ),
    );
  }

  /// Update a conversation by replacing it with [newConversation].
  Future<void> updateConversation(Conversation newConversation) async {
    await waitUntilInitialized();

    emit(
      List.from(
        state.map((c) {
          if (c.jid == newConversation.jid &&
              c.accountJid == newConversation.accountJid) {
            return newConversation;
          }

          return c;
        }).toList()
          ..sort(compareConversation),
      ),
    );
  }

  /// Marks a conversation with JID [jid] and accountJid [accountJid] as closed.
  Future<void> closeConversation(String jid, String accountJid) async {
    await waitUntilInitialized();

    await getForegroundService().send(
      CloseConversationCommand(
        jid: jid,
        // TODO
        // accountJid: accountJid,
      ),
    );

    emit(
      List<Conversation>.from(
        state.where((c) => c.jid != jid && c.accountJid != accountJid).toList(),
      ),
    );
  }
}

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc() : super(ConversationsState()) {
    on<ConversationsInitEvent>(_onInit);
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
        avatarPath: event.avatarUrl,
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
    await getForegroundService().send(
      ExitConversationCommand(
        conversationType: event.type.value,
      ),
      awaitable: false,
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
    await getForegroundService().send(
      CloseConversationCommand(
        jid: event.jid,
      ),
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
    await getForegroundService().send(
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
