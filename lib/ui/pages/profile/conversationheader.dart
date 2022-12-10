import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/service/contacts.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
//import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConversationProfileHeader extends StatelessWidget {
  const ConversationProfileHeader(this.conversation, { super.key });
  final Conversation conversation;

  Future<void> _showAvatarFullsize(BuildContext context, Uint8List? data) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return IgnorePointer(
          child: data != null ?
            Image.memory(data) :
            Image.file(File(conversation.avatarUrl)),
        );
      },
    );
  }
  
  Widget _buildAvatar(BuildContext context, Uint8List? data) {
    final avatar = data != null ?
      CircleAvatar(
        radius: 110,
        backgroundImage: MemoryImage(data),
      ) : 
      AvatarWrapper(
        radius: 110,
        avatarUrl: conversation.avatarUrl,
        altText: conversation.title,
      );

    if (conversation.avatarUrl.isNotEmpty || data != null) {
      return InkWell(
        onTap: () => _showAvatarFullsize(context, data),
        child: avatar,
      );
    }

    return avatar;
  }
  
  @override
  Widget build(BuildContext context) {
    //final subscribed = conversation.subscription == 'both' || conversation.subscription == 'to';
    
    return Column(
      children: [
        Hero(
          tag: 'conversation_profile_picture',
          child: Material(
            child: FutureBuilder<Contact?>(
              future: GetIt.I.get<ContactsUIService>().getContact(
                conversation.contactId,
              ),
              builder: (context, snapshot) {
                final hasData = snapshot.hasData && snapshot.data != null;
                
                if (hasData) {
                  return _buildAvatar(context, snapshot.data!.thumbnail);
                }

                return _buildAvatar(context, null);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FutureBuilder<Contact?>(
            future: GetIt.I.get<ContactsUIService>().getContact(
              conversation.contactId,
            ),
            builder: (_, snapshot) {
              final hasData = snapshot.hasData && snapshot.data != null;

              return Text(
                hasData ?
                  snapshot.data!.displayName :
                  conversation.title,
                style: const TextStyle(
                  fontSize: 30,
                ),
              );
            },
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
                  t.pages.profile.conversation.unmuteChatTooltip :
                  t.pages.profile.conversation.muteChatTooltip,
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
                        t.pages.profile.conversation.unmuteChat :
                        t.pages.profile.conversation.muteChat,
                      style: const TextStyle(
                        fontSize: fontsizeAppbar,
                      ),
                    ),
                  ],
                ),
              ),
              // TODO(PapaTutuWawa): Only show when the chat partner has OMEMO keys
              Tooltip(
                message: t.pages.profile.conversation.devices,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SharedMediaContainer(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColoredBox(
                          color: getTileColor(context),
                          child: const Icon(
                            Icons.security_outlined,
                            size: 32,
                          ),
                        ),
                      ),
                      onTap: () {
                        GetIt.I.get<DevicesBloc>().add(DevicesRequestedEvent(conversation.jid));
                      },
                    ),
                    Text(
                      t.pages.profile.conversation.devices,
                      style: const TextStyle(
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
