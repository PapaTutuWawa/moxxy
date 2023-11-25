import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:synchronized/synchronized.dart';

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

  /// Sets the conversations list.
  Future<void> setConversations(List<Conversation> conversations) async {
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

  Future<void> exitConversation(ConversationType type) async {
    await getForegroundService().send(
      ExitConversationCommand(
        conversationType: type.value,
      ),
      awaitable: false,
    );
  }

  /// Return, if existent, the conversation from the state with a JID equal to [jid].
  /// Returns null, if the conversation does not exist.
  Conversation? getConversationByJid(String jid) {
    // TODO: Consider the accountJid
    return state.firstWhereOrNull((c) => c.jid == jid);
  }
}
