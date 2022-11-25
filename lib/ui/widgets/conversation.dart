import 'dart:async';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';

class ConversationsListRow extends StatefulWidget {
  const ConversationsListRow(
    this.maxTextWidth,
    this.conversation,
    this.update, {
      this.showTimestamp = true,
      this.showLock = false,
      this.extra,
      super.key,
    }
  );
  final Conversation conversation;
  final double maxTextWidth;
  final bool update; // Should a timer run to update the timestamp
  final bool showLock;
  final bool showTimestamp;
  final Widget? extra;

  @override
  ConversationsListRowState createState() => ConversationsListRowState();
}

class ConversationsListRowState extends State<ConversationsListRow> {
  late String _timestampString;
  late Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    final _now = DateTime.now().millisecondsSinceEpoch;

    _timestampString = formatConversationTimestamp(
      widget.conversation.lastChangeTimestamp,
      _now,
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (widget.update && widget.conversation.lastChangeTimestamp > -1 && _now - widget.conversation.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        final now = DateTime.now().millisecondsSinceEpoch;
        setState(() {
          _timestampString = formatConversationTimestamp(
            widget.conversation.lastChangeTimestamp,
            now,
          );
        });

        if (now - widget.conversation.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
          _updateTimer!.cancel();
          _updateTimer = null;
        }
      });
    } else {
      _updateTimer = null;
    }
  }
  
  @override
  void dispose() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }

    super.dispose();
  }

  Widget _buildLastMessageBody() {
    if (widget.conversation.chatState == ChatState.composing) {
      return const TypingIndicatorWidget(Colors.black, Colors.white);
    }

    return Text(
      widget.conversation.lastMessageRetracted ?
        t.messages.retracted :
        widget.conversation.lastMessageBody,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _getLastMessageIcon() {
    switch (widget.conversation.lastMessageState) {
      case lastMessageStateSent: return Icon(Icons.check);
      case lastMessageStateReceived: return Icon(Icons.done_all);
      case lastMessageStateRead: return Icon(
        Icons.done_all,
        color: Colors.blue.shade700,
      );
      case lastMessageStateNothing:
      default:
        return SizedBox();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final badgeText = widget.conversation.unreadCounter > 99 ?
      '99+' :
      widget.conversation.unreadCounter.toString();
    // TODO(Unknown): Maybe turn this into an attribute of the widget to prevent calling this
    //                for every conversation
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth - 24 - 70;
    final textWidth = screenWidth * 0.6;

    final showTimestamp = widget.conversation.lastChangeTimestamp != timestampNever && widget.showTimestamp;
    final sentBySelf = widget.conversation.lastMessageSender == GetIt.I.get<UIDataService>().ownJid!;

    final showBadge = widget.conversation.unreadCounter > 0 && !sentBySelf;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          AvatarWrapper(
            radius: 35,
            avatarUrl: widget.conversation.avatarUrl,
            altText: widget.conversation.title,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: LimitedBox(
              maxWidth: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.conversation.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Visibility(
                        visible: widget.showLock,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.lock,
                            size: 17,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: showTimestamp,
                        child: const Spacer(),
                      ),
                      Visibility(
                        visible: showTimestamp,
                        child: Text(_timestampString),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LimitedBox(
                        maxWidth: textWidth,
                        child: _buildLastMessageBody(),
                      ),
                      const Spacer(),
                      Visibility(
                        visible: showBadge,
                        child: Badge(
                          badgeContent: Text(badgeText),
                          badgeColor: bubbleColorSent,
                        ),
                      ),
                      Visibility(
                        visible: sentBySelf,
                        child: _getLastMessageIcon(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: widget.extra != null,
            child: const Spacer(),
          ),
          ...widget.extra != null ? [widget.extra!] : [],
        ],
      ),
    );
  }
}
