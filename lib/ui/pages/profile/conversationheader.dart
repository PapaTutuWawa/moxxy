import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConversationProfileHeader extends StatelessWidget {

  const ConversationProfileHeader(this.conversation, { Key? key }) : super(key: key);
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'conversation_profile_picture',
          child: Material(
            child: AvatarWrapper(
              radius: 110,
              avatarUrl: conversation.avatarUrl,
              altText: conversation.title,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            conversation.title,
            style: const TextStyle(
              fontSize: 30,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            conversation.jid,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            //mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                message: conversation.muted ?
                  'Unmute chat' :
                  'Mute chat',
                child: SharedMediaContainer(
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColoredBox(
                      color: Color(0xff5c5c5c),
                      child: Icon(
                        conversation.muted ?
                          Icons.do_not_disturb_on :
                          Icons.do_not_disturb_off,
                        size: 32,
                      ),
                    ),
                  ),
                  onTap: () {
                    GetIt.I.get<ProfileBloc>().add(
                      MuteStateSetEvent(
                        conversation.jid,
                        !conversation.muted,
                      ),
                    );
                  },
                ),
              ),
              Tooltip(
                message: 'Stop sharing online status',
                child: SharedMediaContainer(
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColoredBox(
                      color: Color(0xff5c5c5c),
                      child: Icon(
                        conversation.subscription == 'both' || conversation.subscription == 'to' ?
                          PhosphorIcons.link :
                          PhosphorIcons.linkBreak,
                        size: 32,
                      ),
                    ),
                  ),
                  onTap: () {
                    GetIt.I.get<ProfileBloc>().add(
                      SetSubscriptionStateEvent(
                        conversation.jid,
                        // TODO(PapaTutuWawa): Make cleaner
                        !(conversation.subscription == 'both' || conversation.subscription == 'to'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
