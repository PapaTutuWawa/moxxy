import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/ui/state/conversation.dart' as conversation;
import 'package:moxxyv2/ui/state/conversations.dart';
import 'package:moxxyv2/ui/state/share_selection.dart';

part 'newconversation.freezed.dart';

@freezed
class NewConversationState with _$NewConversationState {
  factory NewConversationState({
    @Default(<RosterItem>[]) List<RosterItem> roster,
  }) = _NewConversationState;
}

class NewConversationCubit extends Cubit<NewConversationState> {
  NewConversationCubit() : super(NewConversationState());

  void init(
    List<RosterItem> roster,
  ) {
    return emit(
      state.copyWith(
        roster: roster,
      ),
    );
  }

  Future<void> add(
    String jid,
    String title,
    String? avatarUrl,
    ConversationType type,
  ) async {
    final conversations = GetIt.I.get<ConversationsCubit>();

    final result = await getForegroundService().send(
      AddConversationCommand(
        title: title,
        jid: jid,
        avatarUrl: avatarUrl,
        lastMessageBody: '',
        conversationType: type.value,
      ),
    );

    if (result is NoConversationModifiedEvent) {
      // Fall through
    } else if (result is ConversationUpdatedEvent) {
      await conversations.updateConversation(result.conversation);
    } else if (result is ConversationAddedEvent) {
      await conversations.addConversation(result.conversation);
    }

    await GetIt.I.get<conversation.ConversationCubit>().request(
          jid,
          title,
          avatarUrl,
          removeUntilConversations: true,
        );
  }

  Future<void> remove(String jid) async {
    emit(
      state.copyWith(
        roster: state.roster
            .where(
              (item) => item.jid != jid,
            )
            .toList(),
      ),
    );

    await getForegroundService().send(
      RemoveContactCommand(
        jid: jid,
      ),
      awaitable: false,
    );
  }

  Future<void> onRosterPushed(
    List<RosterItem> added,
    List<RosterItem> modified,
    List<String> removed,
  ) async {
    // TODO(Unknown): Should we guard against adding the same entries multiple times?
    final roster = List<RosterItem>.from(added);

    for (final item in state.roster) {
      // Handle removed items
      if (removed.contains(item.jid)) continue;

      // Handle modified items
      final m = modified.firstWhereOrNull(
        (RosterItem i) => i.jid == item.jid,
      );
      if (m != null) {
        roster.add(m);
      } else {
        roster.add(item);
      }
    }

    // TODO(Unknown): Doing it from here feels absolutely not clean. Maybe change that.
    await GetIt.I.get<ShareSelectionCubit>().onRosterUpdated(
          roster,
        );

    emit(state.copyWith(roster: roster));
  }
}
