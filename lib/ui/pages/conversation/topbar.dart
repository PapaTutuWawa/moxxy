import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/contact_helper.dart';

enum ConversationOption { close, block }

enum EncryptionOption { omemo, none }

PopupMenuItem<T> popupItemWithIcon<T>(
  T value,
  String text,
  IconData icon,
) {
  return PopupMenuItem<T>(
    value: value,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(icon),
        ),
        Text(text),
      ],
    ),
  );
}

/// A custom version of the AppBar to display the conversation topbar
/// as it should
class ConversationTopbar extends StatelessWidget
    implements PreferredSizeWidget {
  const ConversationTopbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  bool _shouldRebuild(ConversationState prev, ConversationState next) {
    return prev.conversation?.title != next.conversation?.title ||
        prev.conversation?.avatarPath != next.conversation?.avatarPath ||
        prev.conversation?.chatState != next.conversation?.chatState ||
        prev.conversation?.jid != next.conversation?.jid ||
        prev.conversation?.type != next.conversation?.type ||
        prev.conversation?.encrypted != next.conversation?.encrypted;
  }

  Widget _buildChatState(ChatState state) {
    switch (state) {
      case ChatState.composing:
      case ChatState.paused:
      case ChatState.active:
        return Text(
          t.pages.conversation.online,
          style: const TextStyle(
            color: Colors.green,
          ),
        );
      case ChatState.inactive:
      case ChatState.gone:
        return const SizedBox();
    }
  }

  bool _isChatStateVisible(ChatState state) {
    return state != ChatState.inactive && state != ChatState.gone;
  }

  /// Summon the profile page of the currently open conversation
  void _openProfile(BuildContext context, ConversationState state) {
    context.read<profile.ProfileBloc>().add(
          profile.ProfilePageRequestedEvent(
            false,
            conversation: state.conversation,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      buildWhen: _shouldRebuild,
      builder: (context, state) {
        final chatState = state.conversation?.chatState ?? ChatState.gone;
        return AppBar(
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                    right: 8,
                    bottom: 8,
                  ),
                  child: InkWell(
                    onTap: () => _openProfile(context, state),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'conversation_profile_picture',
                          child: Material(
                            color: Colors.transparent,
                            child: RebuildOnContactIntegrationChange(
                              builder: () => CachingXMPPAvatar(
                                jid: state.conversation?.jid ?? '',
                                radius: 25,
                                hasContactId:
                                    state.conversation?.contactId != null,
                                isGroupchat:
                                    state.conversation?.isGroupchat ?? false,
                                hash: state.conversation?.avatarHash,
                                path: state.conversation?.avatarPath,
                                shouldRequest: state.conversation != null,
                                altIcon: state.conversation?.isSelfChat ?? false
                                    ? Icons.notes
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          top: _isChatStateVisible(chatState) ? 0 : 10,
                          left: 60,
                          right: 0,
                          curve: Curves.easeInOutCubic,
                          child: RebuildOnContactIntegrationChange(
                            builder: () => Text(
                              state.conversation?.titleWithOptionalContact ??
                                  '',
                              style: const TextStyle(
                                fontSize: fontsizeAppbar,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 25,
                          right: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            opacity: _isChatStateVisible(chatState) ? 1.0 : 0.0,
                            curve: Curves.easeInOutCubic,
                            duration: const Duration(milliseconds: 100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildChatState(chatState),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (state.conversation?.type == ConversationType.chat)
              PopupMenuButton<EncryptionOption>(
                onSelected: (result) {
                  if (result == EncryptionOption.omemo &&
                      state.conversation!.encrypted == false) {
                    context.read<ConversationBloc>().add(OmemoSetEvent(true));
                  } else if (result == EncryptionOption.none &&
                      state.conversation!.encrypted == true) {
                    context.read<ConversationBloc>().add(OmemoSetEvent(false));
                  }
                },
                icon: (state.conversation?.encrypted ?? false)
                    ? const Icon(Icons.lock)
                    : const Icon(Icons.lock_open),
                itemBuilder: (BuildContext c) => [
                  popupItemWithIcon<EncryptionOption>(
                    EncryptionOption.none,
                    t.pages.conversation.unencrypted,
                    Icons.lock_open,
                  ),
                  popupItemWithIcon<EncryptionOption>(
                    EncryptionOption.omemo,
                    t.pages.conversation.encrypted,
                    Icons.lock,
                  ),
                ],
              ),
            PopupMenuButton<ConversationOption>(
              onSelected: (result) async {
                switch (result) {
                  case ConversationOption.close:
                    final result = await showConfirmationDialog(
                      t.pages.conversation.closeChatConfirmTitle,
                      t.pages.conversation.closeChatConfirmSubtext,
                      context,
                    );

                    if (result) {
                      // ignore: use_build_context_synchronously
                      context.read<ConversationsBloc>().add(
                            ConversationClosedEvent(
                              state.conversation!.jid,
                            ),
                          );

                      // Navigate back
                      // ignore: use_build_context_synchronously
                      context.read<NavigationBloc>().add(
                            PoppedRouteEvent(),
                          );
                    }
                  case ConversationOption.block:
                    // ignore: use_build_context_synchronously
                    await blockJid(state.conversation!.jid, context);
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext c) => [
                popupItemWithIcon<ConversationOption>(
                  ConversationOption.close,
                  t.pages.conversation.closeChat,
                  Icons.close,
                ),
                if (state.conversation?.type == ConversationType.chat)
                  popupItemWithIcon<ConversationOption>(
                    ConversationOption.block,
                    t.pages.conversation.blockUser,
                    Icons.block,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
