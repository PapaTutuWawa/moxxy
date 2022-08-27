import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

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

/// A custom version of the Topbar NameAndAvatar style to integrate with
/// bloc.
// TODO(Unknown): If the display name is too long, then it will cause an overflow.
class ConversationTopbarWidget extends StatelessWidget {
  const ConversationTopbarWidget({ Key? key }) : super(key: key);

  bool _shouldRebuild(ConversationState prev, ConversationState next) {
    return prev.conversation?.title != next.conversation?.title
      || prev.conversation?.avatarUrl != next.conversation?.avatarUrl
      || prev.conversation?.chatState != next.conversation?.chatState
      || prev.conversation?.jid != next.conversation?.jid;
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
        return TopbarAvatarAndName(
          IntrinsicHeight(
            child: Column(
              children: [
                TopbarTitleText(state.conversation!.title),
                _buildChatState(state.conversation!.chatState)
              ],
            ),
          ),
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
          () => GetIt.I.get<profile.ProfileBloc>().add(
            profile.ProfilePageRequestedEvent(
              false,
              conversation: context.read<ConversationBloc>().state.conversation,
            ),
          ),
          extra: [
            // ignore: implicit_dynamic_type
            PopupMenuButton(
              onSelected: (result) {
                if (result == EncryptionOption.omemo) {
                  showNotImplementedDialog('End-to-End encryption', context);
                }
              },
              icon: const Icon(Icons.lock_open),
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
                        Navigator.of(context).pop();
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
            )
          ],
        );
      },
    );
  }
}
