import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/keys_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
//import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConversationProfileHeader extends StatelessWidget {

  const ConversationProfileHeader(this.conversation, { Key? key }) : super(key: key);
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    //final subscribed = conversation.subscription == 'both' || conversation.subscription == 'to';
    
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
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            //mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                message: conversation.muted ?
                  'Unmute chat' :
                  'Mute chat',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SharedMediaContainer(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColoredBox(
                          color: getTileColor(context),
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
                    Text(
                      conversation.muted ?
                        'Unmute' :
                        'Mute',
                      style: const TextStyle(
                        fontSize: fontsizeAppbar,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Keys',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SharedMediaContainer(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColoredBox(
                          color: getTileColor(context),
                          child: const Icon(
                            Icons.key,
                            size: 32,
                          ),
                        ),
                      ),
                      onTap: () {
                        GetIt.I.get<KeysBloc>().add(KeysRequestedEvent(conversation.jid));
                      },
                    ),
                    const Text(
                      'Keys',
                      style: TextStyle(
                        fontSize: fontsizeAppbar,
                      ),
                    ),
                  ],
                ),
              ),
              // TODO(Unknown): How to integrate this into the UI?
              /* 
              Tooltip(
                message: subscribed ?
                  'Unsubscribe' :
                  'Subscribe',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SharedMediaContainer(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColoredBox(
                          color: getTileColor(context),
                          child: Icon(
                            subscribed ?
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
                            !subscribed,
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subscribed ?
                          'Unsubscribe' :
                          'Subscribe',
                          style: TextStyle(
                            fontSize: fontsizeAppbar,
                          ),
                        ),

                        Icon(Icons.info),
                      ],
                    ),
                  ],
                ),
              ),*/
            ],
          ),
        ),
      ],
    );
  }
}
