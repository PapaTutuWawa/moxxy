import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/ui/bloc/conversations.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/bloc/newconversation.dart';
import 'package:moxxyv2/ui/bloc/preferences.dart';
import 'package:moxxyv2/ui/bloc/sendfiles.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'share_selection.freezed.dart';

/// The type of data we try to share
enum ShareSelectionType {
  media,
  text,
}

@freezed
class ShareSelectionState with _$ShareSelectionState {
  factory ShareSelectionState({
    // A deduplicated combination of the conversation and roster list
    @Default(<ShareListItem>[]) List<ShareListItem> items,
    // List of paths that we want to share
    @Default(<String>[]) List<String> paths,
    // The text we want to share
    @Default(null) String? text,
    // List of selected items in items
    @Default(<int>[]) List<int> selection,
    // The type of data we try to share
    @Default(ShareSelectionType.media) ShareSelectionType type,
  }) = _ShareSelectionState;
}

/// Create a common ground between Conversations and RosterItems
class ShareListItem {
  const ShareListItem(
    this.avatarPath,
    this.avatarHash,
    this.jid,
    this.title,
    this.isConversation,
    this.conversationType,
    this.isEncrypted,
    this.pseudoRosterItem,
    this.contactId,
    this.contactAvatarPath,
    this.contactDisplayName,
  );
  final String? avatarPath;
  final String? avatarHash;
  final String jid;
  final String title;
  final bool isConversation;
  final ConversationType? conversationType;
  final bool isEncrypted;
  final bool pseudoRosterItem;
  final String? contactId;
  final String? contactAvatarPath;
  final String? contactDisplayName;

  /// Either returns the contact's title (if available), then the item title if the contact
  /// integration is enabled. If not, just returns the item title.
  String get titleWithOptionalContact {
    if (GetIt.I.get<PreferencesCubit>().state.enableContactIntegration) {
      return contactDisplayName ?? title;
    }

    return title;
  }
}

class ShareSelectionCubit extends Cubit<ShareSelectionState> {
  ShareSelectionCubit() : super(ShareSelectionState());

  /// Resets user controllable data, i.e. paths, selections and text
  void reset() {
    emit(state.copyWith(selection: [], paths: [], text: null));
  }

  /// Returns the list of JIDs that are selected.
  List<String> _getRecipients() {
    return state.selection.map((i) => state.items[i].jid).toList();
  }

  void _updateItems(
    List<Conversation> conversations,
    List<RosterItem> rosterItems,
  ) {
    // Use all conversations as a base
    final items = List<ShareListItem>.from(
      conversations.map((c) {
        return ShareListItem(
          c.avatarPath,
          c.avatarHash,
          c.jid,
          c.title,
          true,
          c.type,
          c.encrypted,
          false,
          c.contactId,
          c.contactAvatarPath,
          c.contactDisplayName,
        );
      }),
    );

    // Only add roster items with a JID which we don't already have in items.
    for (final rosterItem in rosterItems) {
      // We look for the index because this way we can update the roster items
      final index =
          items.lastIndexWhere((ShareListItem e) => e.jid == rosterItem.jid);
      if (index == -1) {
        items.add(
          ShareListItem(
            rosterItem.avatarPath,
            rosterItem.avatarHash,
            rosterItem.jid,
            rosterItem.title,
            false,
            null,
            GetIt.I.get<PreferencesCubit>().state.enableOmemoByDefault,
            rosterItem.pseudoRosterItem,
            rosterItem.contactId,
            rosterItem.contactAvatarPath,
            rosterItem.contactDisplayName,
          ),
        );
      } else {
        items[index] = ShareListItem(
          rosterItem.avatarPath,
          rosterItem.avatarHash,
          rosterItem.jid,
          rosterItem.title,
          false,
          null,
          items[index].isEncrypted,
          items[index].pseudoRosterItem,
          items[index].contactId,
          items[index].contactAvatarPath,
          items[index].contactDisplayName,
        );
      }
    }

    emit(state.copyWith(items: items));
  }

  void init(
    List<Conversation> conversations,
    List<RosterItem> rosterItems,
  ) {
    _updateItems(conversations, rosterItems);
  }

  void request(
    List<String> paths,
    String? text,
    ShareSelectionType type,
  ) {
    emit(
      state.copyWith(
        paths: paths,
        text: text,
        type: type,
      ),
    );

    GetIt.I.get<NavigationCubit>().pushNamedAndRemoveUntil(
          const NavigationDestination(shareSelectionRoute),
          (_) => false,
        );
  }

  Future<void> onConversationsUpdated(
    List<Conversation> update,
  ) async {
    _updateItems(
      update,
      GetIt.I.get<NewConversationCubit>().state.roster,
    );
  }

  Future<void> onRosterUpdated(
    List<RosterItem> items,
  ) async {
    _updateItems(
      GetIt.I.get<ConversationsCubit>().state.conversations,
      items,
    );
  }

  Future<void> submit() async {
    if (state.type == ShareSelectionType.text) {
      await getForegroundService().send(
        SendMessageCommand(
          recipients: _getRecipients(),
          body: state.text!,
          chatState: ChatState.gone.toName(),
        ),
      );

      // Navigate to the conversations page...
      await GetIt.I.get<NavigationCubit>().pushNamedAndRemoveUntil(
            const NavigationDestination(homeRoute),
            (_) => false,
          );
      // ...reset the state...
      reset();
      // ...and put the app back into the background
      await MoveToBackground.moveTaskToBack();
    } else {
      await GetIt.I.get<SendFilesCubit>().request(
            state.selection.map((i) {
              final item = state.items[i];
              return SendFilesRecipient(
                item.jid,
                item.title,
                item.avatarPath,
                item.avatarHash,
                item.contactId != null,
              );
            }).toList(),
            // TODO(PapaTutuWawa): Fix
            SendFilesType.media,
            paths: state.paths,
            popEntireStack: true,
          );

      reset();
    }
  }

  Future<void> selectionToggled(
    int index,
  ) async {
    if (state.selection.contains(index)) {
      emit(
        state.copyWith(
          selection: List.from(
            state.selection.where((s) => s != index).toList(),
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          selection: List.from(
            [...state.selection, index],
          ),
        ),
      );
    }
  }
}
