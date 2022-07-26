import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/chat/thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:swipeable_tile/swipeable_tile.dart';

enum ConversationOption {
  close,
  block
}

enum EncryptionOption {
  omemo,
  none
}

PopupMenuItem popupItemWithIcon(dynamic value, String text, IconData icon) {
  // ignore: implicit_dynamic_type
  return PopupMenuItem(
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
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      buildWhen: (prev, next) => prev.showSendButton != next.showSendButton || prev.quotedMessage != next.quotedMessage,
      builder: (context, state) => Container(
        color: const Color.fromRGBO(0, 0, 0, 0),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
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
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  static MaterialPageRoute get route => MaterialPageRoute<dynamic>(builder: (context) => const ConversationPage());
  
  @override
  ConversationPageState createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage> {

  ConversationPageState() :
    _isSpeedDialOpen = ValueNotifier(false),
    _controller = TextEditingController(),
    super();
  final TextEditingController _controller;
  final ValueNotifier<bool> _isSpeedDialOpen;
  
  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Widget _renderBubble(ConversationState state, BuildContext context, int _index, double maxWidth) {
    // TODO(Unknown): Since we reverse the list: Fix start, end and between
    final index = state.messages.length - 1 - _index;
    final item = state.messages[index];
    final start = index - 1 < 0 ? true : state.messages[index - 1].sent != item.sent;
    final end = index + 1 >= state.messages.length ? true : state.messages[index + 1].sent != item.sent;
    final between = !start && !end;

    return SwipeableTile.swipeToTrigger(
      direction: SwipeDirection.horizontal,
      swipeThreshold: 0.2,
      onSwiped: (_) => context.read<ConversationBloc>().add(MessageQuotedEvent(item)),
      backgroundBuilder: (_, direction, progress) {
        // NOTE: Taken from https://github.com/watery-desert/swipeable_tile/blob/main/example/lib/main.dart#L240
        //       and modified.
        var vibrated = false;
        return AnimatedBuilder(
          animation: progress,
          builder: (_, __) {
            if (progress.value > 0.9999 && !vibrated) {
              Vibrate.feedback(FeedbackType.light);
              vibrated = true;
            } else if (progress.value < 0.9999) {
              vibrated = false;
            }

            return Container(
              alignment: direction == SwipeDirection.endToStart ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  right: direction == SwipeDirection.endToStart ? 24.0 : 0.0,
                  left: direction == SwipeDirection.startToEnd ? 24.0 : 0.0,
                ),
                child: Transform.scale(
                  scale: Tween<double>(
                    begin: 0,
                    end: 1.2,
                  )
                  .animate(
                    CurvedAnimation(
                      parent: progress,
                      curve: const Interval(0.5, 1,),
                    ),
                  )
                  .value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.reply,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      isEelevated: false,
      key: ValueKey('message;$item'),
      child: ChatBubble(
        message: item,
        sentBySelf: item.sent,
        start: start,
        end: end,
        between: between,
        maxWidth: maxWidth,
      ),
    );
  }
  
  /// Render a widget that allows the user to either block the user or add them to their
  /// roster
  Widget _renderNotInRosterWidget(ConversationState state, BuildContext context) {
    return Container(
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
  
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    return WillPopScope(
      onWillPop: () async {
        GetIt.I.get<ConversationBloc>().add(CurrentConversationResetEvent());
        return true;
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BlocBuilder<ConversationBloc, ConversationState>(
              buildWhen: (prev, next) => prev.backgroundPath != next.backgroundPath,
              builder: (context, state) {
                final query = MediaQuery.of(context);

                if (state.backgroundPath.isNotEmpty) {
                  return ImageThumbnailWidget(
                    state.backgroundPath,
                    (data) => Image.memory(
                      data,
                      fit: BoxFit.cover,
                      width: query.size.width,
                      height: query.size.height - query.padding.top,
                    ),
                  );
                }

                return SizedBox(
                  width: query.size.width,
                  height: query.size.height,
                  child: Container(
                    color: Theme.of(context).backgroundColor,
                  ),
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
                      ),
                    ),
                  ),

                  _ConversationBottomRow(_controller, _isSpeedDialOpen)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
