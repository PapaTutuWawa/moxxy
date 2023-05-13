import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/reaction_group.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/row.dart';

class ReactionList extends StatelessWidget {
  const ReactionList(this.messageId, this.conversationJid, {super.key});

  final int messageId;

  final String conversationJid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BackgroundEvent?>(
      future: MoxplatformPlugin.handler.getDataSender().sendData(
            GetReactionsForMessageCommand(
              messageId: messageId,
            ),
          ) as Future<BackgroundEvent?>,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final reactionsRaw =
            (snapshot.data! as ReactionsForMessageResult).reactions;
        final ownJid = GetIt.I.get<UIDataService>().ownJid!;
        final ownReactionIndex =
            reactionsRaw.indexWhere((r) => r.jid == ownJid);

        // Ensure that our own reaction is always at index 0. If we have no reactions,
        // insert a "pseudo" entry so that we can add new reactions.
        // TODO: Check if this correctly handles our own reaction at index 0 and at
        //       the last index.
        final reactions = ownReactionIndex == -1
            ? [
                ReactionGroup(
                  ownJid,
                  [],
                ),
                ...reactionsRaw,
              ]
            : [
                reactionsRaw[ownReactionIndex],
                ...reactionsRaw.sublist(0, ownReactionIndex),
                ...reactionsRaw.sublist(ownReactionIndex + 1),
              ];

        return ListView.builder(
          shrinkWrap: true,
          itemCount: reactions.length,
          itemBuilder: (context, index) {
            final reaction = reactions[index];
            return ReactionsRow(
              // TODO
              avatar: const AvatarWrapper(
                radius: 35,
                altIcon: Icons.person,
              ),
              // TODO
              displayName: reaction.jid,
              emojis: reaction.emojis,
              onAddPressed: reaction.jid == ownJid
                  ? () async {
                      final emoji = await pickEmoji(context);
                      if (emoji != null) {
                        await MoxplatformPlugin.handler
                            .getDataSender()
                            .sendData(
                              AddReactionToMessageCommand(
                                messageId: messageId,
                                emoji: emoji,
                                conversationJid: conversationJid,
                              ),
                              awaitable: false,
                            );
                      }
                    }
                  : null,
              onReactionPressed: reaction.jid == ownJid
                  ? (emoji) async {
                      await MoxplatformPlugin.handler.getDataSender().sendData(
                            RemoveReactionFromMessageCommand(
                              messageId: messageId,
                              emoji: emoji,
                              conversationJid: conversationJid,
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
