import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

part 'share_selection_bloc.freezed.dart';
part 'share_selection_event.dart';
part 'share_selection_state.dart';

/// The type of data we try to share
enum ShareSelectionType {
  media,
  text,
}

/// Create a common ground between Conversations and RosterItems
class ShareListItem {
  const ShareListItem(this.avatarPath, this.jid, this.title, this.isConversation);
  final String avatarPath;
  final String jid;
  final String title;
  final bool isConversation;
}

class ShareSelectionBloc extends Bloc<ShareSelectionEvent, ShareSelectionState> {
  ShareSelectionBloc() : super(ShareSelectionState()) {
    on<ShareSelectionInitEvent>(_onShareSelectionInit);
    on<ConversationsModified>(_onConversationsModified);
    on<RosterModifiedEvent>(_onRosterModified);
    on<ShareSelectionRequestedEvent>(_onRequested);
    on<SelectionToggledEvent>(_onSelectionToggled);
    on<SubmittedEvent>(_onSubmit);
    on<ResetEvent>(_onReset);
  }

  /// Resets user controllable data, i.e. paths, selections and text
  void _resetState(Emitter<ShareSelectionState> emit) {
    emit(state.copyWith(selection: [], paths: [], text: null));
  }

  /// Returns the list of JIDs that are selected.
  List<String> _getRecipients() {
    return state.selection
      .map((i) => state.items[i].jid)
      .toList();
  }

  void _updateItems(List<Conversation> conversations, List<RosterItem> rosterItems, Emitter<ShareSelectionState> emit) {
    // Use all conversations as a base
    final items = List<ShareListItem>.from(
      conversations.map((c) {
        return ShareListItem(
          c.avatarUrl,
          c.jid,
          c.title,
          true,
        );
      }),
    );

    // Only add roster items with a JID which we don't already have in items.
    for (final rosterItem in rosterItems) {
      // We look for the index because this way we can update the roster items
      final index = items.lastIndexWhere((ShareListItem e) => e.jid == rosterItem.jid);
      if (index == -1) {
        items.add(
          ShareListItem(
            rosterItem.avatarUrl,
            rosterItem.jid,
            rosterItem.title,
            false,
          ),
        );
      } else {
        items[index] = ShareListItem(
          rosterItem.avatarUrl,
          rosterItem.jid,
          rosterItem.title,
          false,
        );
      }
    }

    emit(state.copyWith(items: items));
  }
  
  Future<void> _onShareSelectionInit(ShareSelectionInitEvent event, Emitter<ShareSelectionState> emit) async {
    _updateItems(event.conversations, event.rosterItems, emit);
  }
  
  Future<void> _onRequested(ShareSelectionRequestedEvent event, Emitter<ShareSelectionState> emit) async {
    emit(state.copyWith(paths: event.paths, text: event.text, type: event.type));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(shareSelectionRoute),
        (_) => false,
      ),
    );
  }

  Future<void> _onConversationsModified(ConversationsModified event, Emitter<ShareSelectionState> emit) async {
    _updateItems(
      event.conversations,
      GetIt.I.get<NewConversationBloc>().state.roster,
      emit,
    );
  }

  Future<void> _onRosterModified(RosterModifiedEvent event, Emitter<ShareSelectionState> emit) async {
    _updateItems(
      GetIt.I.get<ConversationsBloc>().state.conversations,
      event.rosterItems,
      emit,
    );
  }
  
  Future<void> _onSubmit(SubmittedEvent event, Emitter<ShareSelectionState> emit) async {
    if (state.type == ShareSelectionType.text) {
      await MoxplatformPlugin.handler.getDataSender().sendData(
        SendMessageCommand(
          recipients: _getRecipients(),
          body: state.text!,
          chatState: chatStateToString(ChatState.gone),
        ),
      );

      // Navigate to the conversations page...
      GetIt.I.get<NavigationBloc>().add(
        PushedNamedAndRemoveUntilEvent(
          const NavigationDestination(conversationsRoute),
          (_) => false,
        ),
      );
      // ...reset the state...
      _resetState(emit);
      // ...and put the app back into the background
      await MoveToBackground.moveTaskToBack();
    } else {
      GetIt.I.get<SendFilesBloc>().add(
        SendFilesPageRequestedEvent(
          state.selection
            .map((i) => state.items[i].jid)
            .toList(),
          // TODO(PapaTutuWawa): Fix
          SendFilesType.image,
          paths: state.paths,
          popEntireStack: true,
        ),
      );

      _resetState(emit);
    }
  }
  
  Future<void> _onSelectionToggled(SelectionToggledEvent event, Emitter<ShareSelectionState> emit) async {
    if (state.selection.contains(event.index)) {
      emit(
        state.copyWith(
          selection: List.from(
            state.selection
              .where((s) => s != event.index)
              .toList(),
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          selection: List.from(
            [...state.selection, event.index],
          ),
        ),
      );
    }
  } 
  
  Future<void> _onReset(ResetEvent event, Emitter<ShareSelectionState> emit) async {
    _resetState(emit);
  }
}
