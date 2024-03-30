import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:synchronized/synchronized.dart';

part 'conversations.freezed.dart';

@freezed
class ConversationsState with _$ConversationsState {
  factory ConversationsState({
    /// The conversations to display.
    @Default([]) List<Conversation> conversations,

    /// The search results for a search, if performed. Otherwise null.
    @Default(null) List<Conversation>? searchResults,

    /// Flag indicating whether the search is open or not.
    @Default(false) bool searchOpen,

    /// Flag indicating whether we're currently performing a search or not.
    @Default(false) bool isSearching,
  }) = _ConversationsState;
}

/// A BLoC that handles changes to the conversations list. This included adding
/// conversations, updating conversations, and handling different changes, like
/// closing a conversation.
// TODO: Move into a new file.
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit() : super(ConversationsState());

  /// Controller for the search header's [TextField].
  final TextEditingController searchBarController = TextEditingController();

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
    emit(
      state.copyWith(
        conversations: conversations,
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

  /// Add [conversation] to the state.
  Future<void> addConversation(Conversation conversation) async {
    emit(
      state.copyWith(
        conversations: List.from(
          <Conversation>[...state.conversations, conversation]
            ..sort(compareConversation),
        ),
      ),
    );
  }

  /// Update a conversation by replacing it with [newConversation].
  Future<void> updateConversation(Conversation newConversation) async {
    await waitUntilInitialized();

    emit(
      state.copyWith(
        conversations: List.from(
          state.conversations.map((c) {
            if (c.jid == newConversation.jid &&
                c.accountJid == newConversation.accountJid) {
              return newConversation;
            }

            return c;
          }).toList()
            ..sort(compareConversation),
        ),
      ),
    );
  }

  /// Marks the conversation with JID [jid] as read.
  Future<void> markConversationAsRead(String jid) async {
    await waitUntilInitialized();

    await getForegroundService().send(
      MarkConversationAsReadCommand(conversationJid: jid),
      awaitable: false,
    );
  }

  /// Marks a conversation with JID [jid] and accountJid [accountJid] as closed.
  Future<void> closeConversation(String jid, String accountJid) async {
    await waitUntilInitialized();

    await getForegroundService().send(
      CloseConversationCommand(
        jid: jid,
        accountJid: accountJid,
      ),
    );

    emit(
      state.copyWith(
        conversations: List<Conversation>.from(
          state.conversations
              .where((c) => c.jid != jid && c.accountJid != accountJid)
              .toList(),
        ),
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
    return state.conversations.firstWhereOrNull((c) => c.jid == jid);
  }

  /// Sets the searchOpen attribute to [value].
  void setSearchOpen(bool value) {
    emit(
      state.copyWith(
        searchOpen: value,
      ),
    );
  }

  /// Sets the searchResults attribute to null.
  void resetSearchText() {
    searchBarController.text = '';
    emit(
      state.copyWith(
        searchResults: null,
        isSearching: false,
      ),
    );
  }

  void closeSearchBar() {
    searchBarController.text = '';
    emit(
      state.copyWith(
        searchResults: null,
        isSearching: false,
        searchOpen: false,
      ),
    );
  }

  /// Performs the search provided by the header bar. The attribute is just so that
  /// the method can be used directly as a callback.
  Future<void> performSearch(dynamic _) async {
    // Don't search if there is nothing to search for.
    if (searchBarController.text.isEmpty) {
      return;
    }

    emit(state.copyWith(isSearching: true));
    final result = await getForegroundService().send(
      PerformConversationSearch(text: searchBarController.text),
    );

    // In case the user closed the search before it's done, do not update
    // the UI.
    if (!state.searchOpen) {
      return;
    }
    emit(
      state.copyWith(
        searchResults: (result! as ConversationSearchResult).results,
        isSearching: false,
      ),
    );
  }
}
