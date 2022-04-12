import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/bloc/profile_bloc.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:get_it/get_it.dart";

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
          altText: conversation.title
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
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0).add(const EdgeInsets.only(top: 8.0)),
          child: SettingsTile.switchTile(
            title: "Share online status",
            switchValue: conversation.subscription == "to" || conversation.subscription == "both",
            onToggle: (value) {
              GetIt.I.get<ProfileBloc>().add(
                SetSubscriptionStateEvent(
                  conversation.jid,
                  value
                )
              );
            }
          )
        )
      ]
    );
  }
}
