import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:flutter/material.dart";

class ConversationProfileHeader extends StatelessWidget {
  final Conversation conversation;

  const ConversationProfileHeader(this.conversation, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: conversation.avatarUrl,
          alt: Text(conversation.title[0])
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            conversation.title,
            style: const TextStyle(
              fontSize: 30
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            conversation.jid,
            style: const TextStyle(
              fontSize: 15
            )
          )
        )
      ]
    );
  }
}
