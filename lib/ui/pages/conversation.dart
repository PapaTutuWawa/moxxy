import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

/// Sends a block command to the service to block [jid].
void _blockJid(String jid, BuildContext context) {
  showConfirmationDialog(
    'Block $jid?',
    "Are you sure you want to block $jid? You won't receive messages from them until you unblock them.",
    context,
    () {
      context.read<ConversationBloc>().add(JidBlockedEvent(jid));
      Navigator.of(context).pop();
    }
  );
}

/// A custom version of the Topbar NameAndAvatar style to integrate with
/// bloc.
class _ConversationTopbarWidget extends StatelessWidget {
  const _ConversationTopbarWidget({ Key? key }) : super(key: key);

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
                    _blockJid(state.conversation!.jid, context);
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

class _ConversationBottomRow extends StatelessWidget {

  const _ConversationBottomRow(this.controller, this.isSpeedDialOpen);
  final TextEditingController controller;
  final ValueNotifier<bool> isSpeedDialOpen;

  Color _getTextColor(BuildContext context) {
    // TODO(Unknown): Work on the colors
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return Colors.white;
    }

    return Colors.black;
  }
  
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color.fromRGBO(0, 0, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BlocBuilder<ConversationBloc, ConversationState>(
              buildWhen: (prev, next) => prev.showSendButton != next.showSendButton || prev.quotedMessage != next.quotedMessage || prev.emojiPickerVisible != next.emojiPickerVisible,
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      // TODO(Unknown): Work on the colors
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      textColor: _getTextColor(context),
                      enableBoxShadow: true,
                      maxLines: 5,
                      hintText: 'Send a message...',
                      isDense: true,
                      onChanged: (value) {
                        context.read<ConversationBloc>().add(
                          MessageTextChangedEvent(value),
                        );
                      },
                      contentPadding: textfieldPaddingConversation,
                      cornerRadius: textfieldRadiusConversation,
                      controller: controller,
                      topWidget: state.quotedMessage != null ? buildQuoteMessageWidget(
                        state.quotedMessage!,
                        resetQuote: () => context.read<ConversationBloc>().add(QuoteRemovedEvent()),
                      ) : null,
                      prefixIcon: IntrinsicWidth(
                        child: Row(
                          children: [
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.insert_emoticon, size: 24),
                              ),
                              onTap: () {
                                if (!state.emojiPickerVisible) {
                                  dismissSoftKeyboard(context);
                                }

                                context.read<ConversationBloc>().add(EmojiPickerToggledEvent());
                              },
                            ),
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(PhosphorIcons.stickerBold, size: 24),
                              ),
                              onTap: () {},
                            ),
                          ]
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    // NOTE: https://stackoverflow.com/a/52786741
                    //       Thank you kind sir
                    child: SizedBox(
                      height: 45,
                      width: 45,
                      child: FittedBox(
                        child: SpeedDial(
                          icon: state.showSendButton ? Icons.send : Icons.add,
                          curve: Curves.bounceInOut,
                          backgroundColor: primaryColor,
                          // TODO(Unknown): Theme dependent?
                          foregroundColor: Colors.white,
                          openCloseDial: isSpeedDialOpen,
                          onPress: () {
                            if (state.showSendButton) {
                              context.read<ConversationBloc>().add(
                                MessageSentEvent(),
                              );
                              controller.text = '';
                            } else {
                              isSpeedDialOpen.value = true;
                            }
                          },
                          children: [
                            SpeedDialChild(
                              child: const Icon(Icons.image),
                              onTap: () {
                                context.read<ConversationBloc>().add(ImagePickerRequestedEvent());
                              },
                              backgroundColor: primaryColor,
                              // TODO(Unknown): Theme dependent?
                              foregroundColor: Colors.white,
                              label: 'Send Images',
                            ),
                            SpeedDialChild(
                              child: const Icon(Icons.photo_camera),
                              onTap: () {
                                showNotImplementedDialog('taking photos', context);
                              },
                              backgroundColor: primaryColor,
                              // TODO(Unknown): Theme dependent?
                              foregroundColor: Colors.white,
                              label: 'Take photo',
                            ),
                            SpeedDialChild(
                              child: const Icon(Icons.attach_file),
                              onTap: () {
                                context.read<ConversationBloc>().add(FilePickerRequestedEvent());
                              },
                              backgroundColor: primaryColor,
                              // TODO(Unknown): Theme dependent?
                              foregroundColor: Colors.white,
                              label: 'Send files',
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          BlocBuilder<ConversationBloc, ConversationState>(
            buildWhen: (prev, next) => prev.emojiPickerVisible != next.emojiPickerVisible,
            builder: (context, state) => Offstage(
              offstage: !state.emojiPickerVisible,
              child: SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (_, emoji) {

                  },
                  config: Config(
                    bgColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const ConversationPage(),
    settings: const RouteSettings(
      name: conversationRoute,
    ),
  );
  
  @override
  ConversationPageState createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage> {

  ConversationPageState() :
    _isSpeedDialOpen = ValueNotifier(false),
    _controller = TextEditingController(),
    _scrollController = ScrollController(),
    super();
  final TextEditingController _controller;
  final ValueNotifier<bool> _isSpeedDialOpen;
  final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  Widget _renderBubble(ConversationState state, BuildContext context, int _index, double maxWidth) {
    // TODO(Unknown): Since we reverse the list: Fix start, end and between
    final index = state.messages.length - 1 - _index;
    final item = state.messages[index];
    final start = index - 1 < 0 ? true : state.messages[index - 1].sent != item.sent;
    final end = index + 1 >= state.messages.length ? true : state.messages[index + 1].sent != item.sent;
    final between = !start && !end;
    final lastMessageTimestamp = index > 0 ? state.messages[index - 1].timestamp : null;
    
    return ChatBubble(
      message: item,
      sentBySelf: item.sent,
      start: start,
      end: end,
      between: between,
      maxWidth: maxWidth,
      lastMessageTimestamp: lastMessageTimestamp,
      onSwipedCallback: (_) => context.read<ConversationBloc>().add(MessageQuotedEvent(item)),
    );
  }
  
  /// Render a widget that allows the user to either block the user or add them to their
  /// roster
  Widget _renderNotInRosterWidget(ConversationState state, BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                child: const Text('Add to contacts'),
                onPressed: () {
                  final jid = state.conversation!.jid;
                  showConfirmationDialog(
                    'Add $jid to your contacts?',
                    'Are you sure you want to add $jid to your conacts?',
                    context,
                    () {
                      // TODO(Unknown): Maybe show a progress indicator
                      // TODO(Unknown): Have the page update its state once the addition is done
                      context.read<ConversationBloc>().add(
                        JidAddedEvent(jid),
                      );
                      Navigator.of(context).pop();
                    }
                  );
                },
              ),
            ),
            Expanded(
              child: TextButton(
                child: const Text('Block'),
                onPressed: () => _blockJid(state.conversation!.jid, context),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Taken from https://bloclibrary.dev/#/flutterinfinitelisttutorial
  bool _isScrolledToBottom() {
    if (!_scrollController.hasClients) return false;

    return _scrollController.offset <= 10;
  }
  
  void _onScroll() {

    GetIt.I.get<ConversationBloc>().add(ScrollStateSetEvent(_isScrolledToBottom()));
  }
  
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
   
    return WillPopScope(
      onWillPop: () async {
        final bloc = GetIt.I.get<ConversationBloc>();

        if (bloc.state.emojiPickerVisible) {
          bloc.add(EmojiPickerToggledEvent());
          return false;
        } else {
          bloc.add(CurrentConversationResetEvent());
          return true;
        }
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BlocBuilder<ConversationBloc, ConversationState>(
              buildWhen: (prev, next) => prev.backgroundPath != next.backgroundPath,
              builder: (context, state) {
                final query = MediaQuery.of(context);

                if (state.backgroundPath.isNotEmpty) {
                  return Image.file(
                    File(state.backgroundPath),
                    fit: BoxFit.cover,
                    width: query.size.width,
                    height: query.size.height - query.padding.top,
                  );
                }

                return SizedBox(
                  width: query.size.width,
                  height: query.size.height,
                  child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Scaffold(
              // TODO(Unknown): Maybe replace the scaffold itself to prevent transparency
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              appBar: const BorderlessTopbar(_ConversationTopbarWidget()),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<ConversationBloc, ConversationState>(
                    buildWhen: (prev, next) => prev.conversation?.inRoster != next.conversation?.inRoster,
                    builder: (context, state) {
                      if (state.conversation!.inRoster) return Container();

                      return _renderNotInRosterWidget(state, context);
                    },
                  ),

                  BlocBuilder<ConversationBloc, ConversationState>(
                    buildWhen: (prev, next) => prev.messages != next.messages,
                    builder: (context, state) => Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) => _renderBubble(state, context, index, maxWidth),
                        shrinkWrap: true,
                        controller: _scrollController,
                      ),
                    ),
                  ),

                  _ConversationBottomRow(_controller, _isSpeedDialOpen)
                ],
              ),
            ),
          ),

          Positioned(
            right: 8,
            bottom: 96,
            child: BlocBuilder<ConversationBloc, ConversationState>(
              buildWhen: (prev, next) => prev.scrolledToBottom != next.scrolledToBottom,
              builder: (_, state) => _renderScrollToBottom(context, !state.scrolledToBottom),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderScrollToBottom(BuildContext context, bool visible) {
    if (visible) {
      return Material(
        color: const Color.fromRGBO(0, 0, 0, 0),
        child: Ink(
          decoration: ShapeDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: const CircleBorder(),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: () {
              _scrollController.jumpTo(0);
            },
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }  
}
