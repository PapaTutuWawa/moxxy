import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/reaction_group.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/state/account.dart';
import 'package:moxxyv2/ui/state/conversations.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/row.dart';

/// If a reaction group from our own JID [ownJid] is included in [group], ensure that
/// that reaction group is at index 0. If no reactions from our JID are included, insert
/// a new group with an empty emoji list at index 0.
@visibleForTesting
List<ReactionGroup> ensureReactionGroupOrder(
  List<ReactionGroup> group,
  String ownJid,
) {
  final ownReactionIndex = group.indexWhere((r) => r.jid == ownJid);
  return ownReactionIndex == -1
      ? [
          ReactionGroup(
            ownJid,
            [],
          ),
          ...group,
        ]
      : [
          group[ownReactionIndex],
          ...group.sublist(0, ownReactionIndex),
          ...group.sublist(ownReactionIndex + 1),
        ];
}

/// Displays the reactions to a message and allows modifying the reactions.
/// When created, fetches the reactions from the ReactionService.
class ReactionList extends StatelessWidget {
  const ReactionList(this.messageId, {super.key});

  /// The database identifier of the message to fetch reactions of.
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BackgroundEvent?>(
      future: getForegroundService().send(
        GetReactionsForMessageCommand(
          id: messageId,
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final reactionsRaw =
            (snapshot.data! as ReactionsForMessageResult).reactions;
        final ownJid = GetIt.I.get<AccountCubit>().state.account.jid;

        // Ensure that our own reaction is always at index 0. If we have no reactions,
        // insert a "pseudo" entry so that we can add new reactions.
        final reactions = ensureReactionGroupOrder(reactionsRaw, ownJid);

        final bloc = GetIt.I.get<ConversationsCubit>();
        return ListView.builder(
          shrinkWrap: true,
          itemCount: reactions.length,
          itemBuilder: (context, index) {
            final reaction = reactions[index];
            final ownReaction = reaction.jid == ownJid;
            final conversation =
                ownReaction ? null : bloc.getConversationByJid(reaction.jid);
            return ReactionsRow(
              avatar: ownReaction
                  ? CachingXMPPAvatar.self(
                      borderRadius: 35,
                      size: 70,
                    )
                  : CachingXMPPAvatar(
                      borderRadius: 35,
                      size: 70,
                      jid: reaction.jid,
                      isGroupchat: false,
                      // TODO(Unknown): This will break with groupchats
                      hasContactId: conversation?.contactId != null,
                      path: conversation?.avatarPath,
                      hash: conversation?.avatarHash,
                    ),
              displayName: reaction.jid == ownJid
                  ? t.messages.you
                  : conversation?.title ?? reaction.jid,
              emojis: reaction.emojis,
              onAddPressed: reaction.jid == ownJid
                  ? () async {
                      final emoji = await pickEmoji(context);
                      if (emoji != null) {
                        await getForegroundService().send(
                          AddReactionToMessageCommand(
                            id: messageId,
                            emoji: emoji,
                          ),
                          awaitable: false,
                        );
                      }
                    }
                  : null,
              onReactionPressed: reaction.jid == ownJid
                  ? (emoji) async {
                      await getForegroundService().send(
                        RemoveReactionFromMessageCommand(
                          id: messageId,
                          emoji: emoji,
                        ),
                        awaitable: false,
                      );

                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}
