import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/row.dart';

class ReactionList extends StatelessWidget {
  const ReactionList(this.messageId, {super.key});

  final int messageId;

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
          return Center(
            child: const CircularProgressIndicator(),
          );
        }

        final reactions = (snapshot.data! as ReactionsForMessageResult).reactions;
        final ownJid = GetIt.I.get<UIDataService>().ownJid!;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: reactions.length,
          itemBuilder: (context, index) {
            final reaction = reactions[index];
            return ReactionsRow(
              // TODO
              avatar: AvatarWrapper(
                radius: 35,
                altIcon: Icons.person,
              ),
              // TODO
              displayName: reaction.jid,
              emojis: reaction.emojis,
              // TODO
              onAddPressed: reaction.jid == ownJid
                ? () {}
                : null,
              onReactionPressed: reaction.jid == ownJid
                ? (_) {}
                : null,
            );
          },
        );
      },
    ); 
  }
}
