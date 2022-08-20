import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/bottom.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/topbar.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

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
                onPressed: () => blockJid(state.conversation!.jid, context),
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
          bloc.add(EmojiPickerToggledEvent(handleKeyboard: false));
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
              appBar: const BorderlessTopbar(ConversationTopbarWidget()),
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

                  ConversationBottomRow(_controller, _isSpeedDialOpen)
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
