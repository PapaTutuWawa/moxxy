import "dart:io";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/chatbubble.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/quotedmessage.dart";
import "package:moxxyv2/ui/bloc/conversation_bloc.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/shared/models/message.dart";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:swipeable_tile/swipeable_tile.dart";
import "package:flutter_vibrate/flutter_vibrate.dart";

typedef SendMessageFunction = void Function(String body);

enum ConversationOption {
  close,
  block
}

enum EncryptionOption {
  omemo,
  none
}

PopupMenuItem popupItemWithIcon(dynamic value, String text, IconData icon) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(icon)
        ),
        Text(text)
      ]
    )
  );
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _controller;
  final ValueNotifier<bool> _isSpeedDialOpen;

  _ConversationPageState() :
    _isSpeedDialOpen = ValueNotifier(false),
    _controller = TextEditingController(),
    super();
  
  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Widget _renderBubble(ConversationState state, BuildContext context, int _index, double maxWidth) {
    // TODO: Since we reverse the list: Fix start, end and between
    final index = state.messages.length - 1 - _index;
    Message item = state.messages[index];
    bool start = index - 1 < 0 ? true : state.messages[index - 1].sent != item.sent;
    bool end = index + 1 >= state.messages.length ? true : state.messages[index + 1].sent != item.sent;
    bool between = !start && !end;

    return SwipeableTile.swipeToTrigger(
      direction: SwipeDirection.horizontal,
      swipeThreshold: 0.2,
      onSwiped: (_) => context.read<ConversationBloc>().add(MessageQuotedEvent(item)),
      backgroundBuilder: (_, direction, progress) {
        // NOTE: Taken from https://github.com/watery-desert/swipeable_tile/blob/main/example/lib/main.dart#L240
        //       and modified.
        bool vibrated = false;
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
                  left: direction == SwipeDirection.startToEnd ? 24.0 : 0.0
                ),
                child: Transform.scale(
                  scale: Tween<double>(
                    begin: 0.0,
                    end: 1.2,
                  )
                  .animate(
                    CurvedAnimation(
                      parent: progress,
                      curve: const Interval(0.5, 1.0,
                        curve: Curves.linear),
                    ),
                  )
                  .value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.reply,
                        color: Colors.white,
                      )
                    )
                  ),
                ),
              ),
            );
          },
        );
      },
      isEelevated: false,
      key: ValueKey("message;" + item.toString()),
      child: ChatBubble(
        message: item,
        sentBySelf: item.sent,
        start: start,
        end: end,
        between: between,
        maxWidth: maxWidth,
      )
    );
  }

  void _block(ConversationState state, BuildContext context) {
    final jid = state.conversation!.jid;

    showConfirmationDialog(
      "Block $jid?",
      "Are you sure you want to block $jid? You won't receive messages from them until you unblock them.",
      context,
      () {
        context.read<ConversationBloc>().add(JidBlockedEvent(jid));
        Navigator.of(context).pop();
      }
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
                child: const Text("Add to contacts"),
                onPressed: () {
                  final jid = state.conversation!.jid;
                  showConfirmationDialog(
                    "Add $jid to your contacts?",
                    "Are you sure you want to add $jid to your conacts?",
                    context,
                    () {
                      // TODO: Maybe show a progress indicator
                      // TODO: Have the page update its state once the addition is done
                      context.read<ConversationBloc>().add(
                        JidAddedEvent(jid)
                      );
                      Navigator.of(context).pop();
                    }
                  );
                }
              )
            ),
            Expanded(
              child: TextButton(
                child: const Text("Block"),
                onPressed: () => _block(state, context)
              )
            )
          ]
        )
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    return BlocBuilder<ConversationBloc, ConversationState>(
      buildWhen: (prev, next) {
        print("============== BUILD WHEN ==============");
        print(prev.toString());
        print(next.toString());

        return prev != next;
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            context.read<ConversationBloc>().add(CurrentConversationResetEvent());
            return true;
          },
          child: Scaffold(
            appBar: BorderlessTopbar.avatarAndName(
              avatar: AvatarWrapper(
                radius: 25.0,
                avatarUrl: state.conversation!.avatarUrl,
                alt: Text(state.conversation!.title[0])
              ),
              title: state.conversation!.title,
              // TODO
              //onTapFunction: () => Navigator.pushNamed(context, profileRoute, arguments: ProfilePageArguments(conversation: viewModel.conversation, isSelfProfile: false)),
              onTapFunction: () {},
              showBackButton: true,
              extra: [
                PopupMenuButton(
                  onSelected: (result) {
                    if (result == EncryptionOption.omemo) {
                      showNotImplementedDialog("End-to-End encryption", context);
                    }
                  },
                  icon: const Icon(Icons.lock_open),
                  itemBuilder: (BuildContext c) => [
                    popupItemWithIcon(EncryptionOption.none, "Unencrypted", Icons.lock_open),
                    popupItemWithIcon(EncryptionOption.omemo, "Encrypted", Icons.lock),
                  ]
                ),
                PopupMenuButton(
                  onSelected: (result) {
                    switch (result) {
                      case ConversationOption.close: {
                        showConfirmationDialog(
                          "Close Chat",
                          "Are you sure you want to close this chat?",
                          context,
                          () {
                            // TODO
                            //viewModel.closeChat();
                            Navigator.of(context).pop();
                          }
                        );
                      }
                      break;
                      case ConversationOption.block: {
                        _block(state, context);
                      }
                      break;
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (BuildContext c) => [
                    popupItemWithIcon(ConversationOption.close, "Close chat", Icons.close),
                    popupItemWithIcon(ConversationOption.block, "Block contact", Icons.block)
                  ]
                )
              ]
            ),
            body: Container(
              decoration: state.backgroundPath.isNotEmpty ? BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(state.backgroundPath))
                )
              ) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...(!state.conversation!.inRoster ? [ _renderNotInRosterWidget(state, context) ] : []),

                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) => _renderBubble(state, context, index, maxWidth),
                      shrinkWrap: true
                    )
                  ),

                  // TODO: Typing indicator
                  /*
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container( 
                      decoration: BoxDecoration(
                        color: bubbleColorReceived,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 80,
                      height: 45,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                              )
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                              )
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                              )
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                              )
                            )
                          ]
                        )
                      )
                    )
                  ),
                  */
                  
                  Container(
                    color: Theme.of(context).backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              maxLines: 5,
                              minLines: 1,
                              hintText: "Send a message...",
                              isDense: true,
                              onChanged: (value) {
                                context.read<ConversationBloc>().add(
                                  MessageTextChangedEvent(value)
                                );
                              },
                              contentPadding: textfieldPaddingConversation,
                              cornerRadius: textfieldRadiusConversation,
                              controller: _controller,
                              // TODO: Handle media messages being quoted
                              topWidget: state.quotedMessage != null ? QuotedMessageWidget(
                                message: state.quotedMessage!,
                                resetQuotedMessage: () => context.read<ConversationBloc>().add(QuoteRemovedEvent())
                              ) : null
                            )
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            // NOTE: https://stackoverflow.com/a/52786741
                            //       Thank you kind sir
                            child: SizedBox(
                              height: 45.0,
                              width: 45.0,
                              child: FittedBox(
                                child: SpeedDial(
                                  icon: state.showSendButton ? Icons.send : Icons.add,
                                  visible: true,
                                  curve: Curves.bounceInOut,
                                  backgroundColor: primaryColor,
                                  // TODO: Theme dependent?
                                  foregroundColor: Colors.white,
                                  openCloseDial: _isSpeedDialOpen,
                                  onPress: () {
                                    if (state.showSendButton) {
                                      context.read<ConversationBloc>().add(
                                        MessageSentEvent()
                                      );
                                      _controller.text = "";
                                    } else {
                                      _isSpeedDialOpen.value = true;
                                    }
                                  },
                                  children: [
                                    SpeedDialChild(
                                      child: const Icon(Icons.image),
                                      onTap: () {
                                        showNotImplementedDialog("sending files", context);
                                        //Navigator.pushNamed(context, sendFilesRoute);
                                      },
                                      backgroundColor: primaryColor,
                                      // TODO: Theme dependent?
                                      foregroundColor: Colors.white,
                                      label: "Send Image"
                                    ),
                                    SpeedDialChild(
                                      child: const Icon(Icons.photo_camera),
                                      onTap: () {
                                        showNotImplementedDialog("sending files", context);
                                      },
                                      backgroundColor: primaryColor,
                                      // TODO: Theme dependent?
                                      foregroundColor: Colors.white,
                                      label: "Take photo"
                                    ),
                                    SpeedDialChild(
                                      child: const Icon(Icons.attach_file),
                                      onTap: () {
                                        showNotImplementedDialog("sending files", context);
                                      },
                                      backgroundColor: primaryColor,
                                      // TODO: Theme dependent?
                                      foregroundColor: Colors.white,
                                      label: "Add file"
                                    ),
                                  ]
                                )
                              )
                            )
                          )
                        ]
                      )
                    )
                  )
                ]
              )
            )
          )
        );
      }
    );
  }
}
