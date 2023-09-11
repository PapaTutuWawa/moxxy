import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart' as navigation;
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';

class ShareSelectionPage extends StatelessWidget {
  const ShareSelectionPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const ShareSelectionPage(),
        settings: const RouteSettings(
          name: shareSelectionRoute,
        ),
      );

  bool _buildWhen(ShareSelectionState prev, ShareSelectionState next) {
    // Prevent rebuilding when items changes. This prevents us from having to deal with
    // a roster update coming in while we are selecting JIDs to share to.
    // TODO(Unknown): But does it work?
    return prev.selection != next.selection ||
        prev.paths != next.paths ||
        prev.text != next.text ||
        prev.type != next.type;
  }

  IconData? _getSuffixIcon(ShareListItem item) {
    if (item.pseudoRosterItem) {
      return Icons.smartphone;
    }

    if (item.isEncrypted) {
      return Icons.lock;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        GetIt.I.get<ShareSelectionBloc>().add(ResetEvent());

        // Navigate to the conversations page...
        GetIt.I.get<navigation.NavigationBloc>().add(
              navigation.PushedNamedAndRemoveUntilEvent(
                const navigation.NavigationDestination(conversationsRoute),
                (_) => false,
              ),
            );
        // ...and put the app back into the background
        await MoveToBackground.moveTaskToBack();

        return false;
      },
      child: BlocBuilder<ShareSelectionBloc, ShareSelectionState>(
        buildWhen: _buildWhen,
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(t.pages.shareselection.shareWith),
          ),
          body: ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];

              return ConversationsListRow(
                Conversation(
                  '',
                  item.titleWithOptionalContact,
                  null,
                  item.avatarPath,
                  item.avatarHash,
                  item.jid,
                  null,
                  0,
                  item.conversationType ?? ConversationType.chat,
                  0,
                  true,
                  true,
                  false,
                  false,
                  ChatState.gone,
                  contactId: item.contactId,
                  contactAvatarPath: item.contactAvatarPath,
                  contactDisplayName: item.contactDisplayName,
                ),
                false,
                titleSuffixIcon: _getSuffixIcon(item),
                showTimestamp: false,
                isSelected: state.selection.contains(index),
                onPressed: () {
                  context.read<ShareSelectionBloc>().add(
                        SelectionToggledEvent(index),
                      );
                },
              );
            },
          ),
          floatingActionButton: state.selection.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () async {
                    final bloc = context.read<ShareSelectionBloc>();
                    final hasUnencrypted =
                        bloc.state.selection.any((selection) {
                      return !bloc.state.items[selection].isEncrypted;
                    });
                    final hasEncrypted = bloc.state.selection.any((selection) {
                      return bloc.state.items[selection].isEncrypted;
                    });

                    // Warn the user
                    if (hasUnencrypted && hasEncrypted) {
                      final result = await showConfirmationDialog(
                        t.pages.shareselection.confirmTitle,
                        t.pages.shareselection.confirmBody,
                        context,
                      );

                      if (result) {
                        bloc.add(SubmittedEvent());
                      }
                      return;
                    }

                    bloc.add(SubmittedEvent());
                  },
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
