import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum ConversationOption {
  close,
  block
}

enum EncryptionOption {
  omemo,
  none
}

PopupMenuItem<dynamic> popupItemWithIcon(dynamic value, String text, IconData icon) {
  return PopupMenuItem<dynamic>(
    value: value,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(icon),
        ),
        Text(text)
      ],
    ),
  );
}

/// A custom version of the BorderlessTopbar to display the conversation topbar
/// as it should
// TODO(PapaTutuWawa): The conversation title may overflow the Topbar
// TODO(Unknown): Maybe merge with BorderlessTopbar
// TODO(PapaTutuWawa): Make the conversation title go up, when we display "online" and down if we don't have to anymore
class ConversationTopbar extends StatelessWidget implements PreferredSizeWidget {
  const ConversationTopbar({ Key? key }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  bool _shouldRebuild(ConversationState prev, ConversationState next) {
    return prev.conversation?.title != next.conversation?.title
      || prev.conversation?.avatarUrl != next.conversation?.avatarUrl
      || prev.conversation?.chatState != next.conversation?.chatState
      || prev.conversation?.jid != next.conversation?.jid
      || prev.conversation?.encrypted != next.conversation?.encrypted;
  }
  
  Widget _buildChatState(ChatState state) {
    switch (state) {
      case ChatState.paused:
      case ChatState.active:
        return const Text(
          'Online',
          style: TextStyle(
            color: Colors.green,
          ),
        );
      case ChatState.composing:
        // TODO(Unknown): Colors
        return const TypingIndicatorWidget(Colors.black, Colors.white);
      case ChatState.inactive:
      case ChatState.gone:
        return Container();
    } 
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      buildWhen: _shouldRebuild,
      builder: (context, state) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SafeArea(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
                    const BackButton(),
                    Hero(
                      tag: 'conversation_profile_picture',
                      child: Material(
                        color: const Color.fromRGBO(0, 0, 0, 0),
                        child: AvatarWrapper(
                          radius: 25,
                          avatarUrl: state.conversation!.avatarUrl,
                          altText: state.conversation!.title,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => GetIt.I.get<profile.ProfileBloc>().add(
                          profile.ProfilePageRequestedEvent(
                            false,
                            conversation: context.read<ConversationBloc>().state.conversation,
                          ),
                        ),
                        child: Column(
                          children: [
                            TopbarTitleText(state.conversation!.title),
                            _buildChatState(state.conversation!.chatState),
                          ],
                        ),
                      ),
                    ),
                    // ignore: implicit_dynamic_type
                    PopupMenuButton(
                      onSelected: (result) {
                        if (result == EncryptionOption.omemo && state.conversation!.encrypted == false) {
                          context.read<ConversationBloc>().add(OmemoSetEvent(true));
                        } else if (result == EncryptionOption.none && state.conversation!.encrypted == true) {
                          context.read<ConversationBloc>().add(OmemoSetEvent(false));
                        }
                      },
                      icon: state.conversation!.encrypted ?
                      const Icon(Icons.lock) :
                      const Icon(Icons.lock_open),
                      itemBuilder: (BuildContext c) => [
                        popupItemWithIcon(EncryptionOption.none, 'Unencrypted', Icons.lock_open),
                        popupItemWithIcon(EncryptionOption.omemo, 'Encrypted', Icons.lock),
                      ],
                    ),
                    // ignore: implicit_dynamic_type
                    PopupMenuButton(
                      onSelected: (result) {
                        switch (result) {
                          case ConversationOption.close: {
                            showConfirmationDialog(
                              'Close Chat',
                              'Are you sure you want to close this chat?',
                              context,
                              () {
                                context.read<ConversationsBloc>().add(
                                  ConversationClosedEvent(state.conversation!.jid),
                                );
                              }
                            );
                          }
                          break;
                          case ConversationOption.block: {
                            blockJid(state.conversation!.jid, context);
                          }
                          break;
                        }
                      },
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (BuildContext c) => [
                        popupItemWithIcon(ConversationOption.close, 'Close chat', Icons.close),
                        popupItemWithIcon(ConversationOption.block, 'Block contact', Icons.block)
                      ],
                    ),
                  ],
                ),
              ),
            ),   
          ),
        );
      },
    );
  }
}
