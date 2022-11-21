import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
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
class ConversationTopbar extends StatelessWidget implements PreferredSizeWidget {
  const ConversationTopbar({ super.key });

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
        return Text(
          t.pages.conversation.online,
          style: const TextStyle(
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

  bool _isChatStateVisible(ChatState state) {
    return state != ChatState.inactive && state != ChatState.gone;
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
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              top: _isChatStateVisible(state.conversation!.chatState) ?
                                0 :
                                10,
                              left: 0,
                              right: 0,
                              curve: Curves.easeInOutCubic,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TopbarTitleText(state.conversation!.title),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                opacity: _isChatStateVisible(state.conversation!.chatState) ?
                                  1.0 :
                                  0.0,
                                curve: Curves.easeInOutCubic,
                                duration: const Duration(milliseconds: 100),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildChatState(state.conversation!.chatState),
                                  ],
                                ),
                              ),
                            ),
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
                        popupItemWithIcon(EncryptionOption.none, t.pages.conversation.unencrypted, Icons.lock_open),
                        popupItemWithIcon(EncryptionOption.omemo, t.pages.conversation.encrypted, Icons.lock),
                      ],
                    ),
                    // ignore: implicit_dynamic_type
                    PopupMenuButton(
                      onSelected: (result) async {
                        switch (result) {
                          case ConversationOption.close: {
                            final result = await showConfirmationDialog(
                              t.pages.conversation.closeChatConfirmTitle,
                              t.pages.conversation.closeChatConfirmSubtext,
                              context,
                            );

                            if (result) {
                              // ignore: use_build_context_synchronously
                              context.read<ConversationsBloc>().add(
                                ConversationClosedEvent(state.conversation!.jid),
                              );
                            }
                          }
                          break;
                          case ConversationOption.block: {
                            await blockJid(state.conversation!.jid, context);
                          }
                          break;
                        }
                      },
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (BuildContext c) => [
                        popupItemWithIcon(ConversationOption.close, t.pages.conversation.closeChat, Icons.close),
                        popupItemWithIcon(ConversationOption.block, t.pages.conversation.blockUser, Icons.block)
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
