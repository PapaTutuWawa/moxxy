import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'share_selection_bloc.freezed.dart';
part 'share_selection_event.dart';
part 'share_selection_state.dart';

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
    on<ShareSelectionRequestedEvent>(_onRequested);
    on<SelectionToggledEvent>(_onSelectionToggled);
    on<ResetEvent>(_onReset);
  }

  Future<void> _onShareSelectionInit(ShareSelectionInitEvent event, Emitter<ShareSelectionState> emit) async {
    // Use all conversations as a base
    final items = List<ShareListItem>.from(
      event.conversations.map((c) {
        return ShareListItem(
          c.avatarUrl,
          c.jid,
          c.title,
          true,
        );
      }),
    );

    // Only add roster items with a JID which we don't already have in items.
    for (final rosterItem in event.rosterItems) {
      if (!listContains(items, (ShareListItem e) => e.jid == rosterItem.jid)) {
        items.add(
          ShareListItem(
            rosterItem.avatarUrl,
            rosterItem.jid,
            rosterItem.title,
            false,
          ),
        );
      }
    }

    emit(state.copyWith(items: items));
  }

  Future<void> _onRequested(ShareSelectionRequestedEvent event, Emitter<ShareSelectionState> emit) async {
    emit(state.copyWith(paths: event.paths));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(shareSelectionRoute),
      ),
    );
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
    emit(state.copyWith(selection: [], paths: []));
  }
}
