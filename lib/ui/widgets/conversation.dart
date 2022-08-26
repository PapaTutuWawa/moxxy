import 'dart:async';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';

class ConversationsListRow extends StatefulWidget {
  
  const ConversationsListRow(
    this.avatarUrl,
    this.name,
    this.lastMessageBody,
    this.unreadCount,
    this.maxTextWidth,
    this.lastChangeTimestamp,
    this.update, {
      this.typingIndicator = false,
      this.extra,
      Key? key,
    }
  ) : super(key: key);
  final String avatarUrl;
  final String name;
  final String lastMessageBody;
  final int unreadCount;
  final double maxTextWidth;
  final int lastChangeTimestamp;
  final bool update; // Should a timer run to update the timestamp
  final bool typingIndicator;
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
      widget.lastChangeTimestamp,
      _now,
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (widget.update && widget.lastChangeTimestamp > -1 && _now - widget.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        final now = DateTime.now().millisecondsSinceEpoch;
        setState(() {
          _timestampString = formatConversationTimestamp(
            widget.lastChangeTimestamp,
            now,
          );
        });

        if (now - widget.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
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
    if (widget.typingIndicator) {
      return const TypingIndicatorWidget(Colors.black, Colors.white);
    }

    return Text(
      widget.lastMessageBody,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final badgeText = widget.unreadCount > 99 ? '99+' : widget.unreadCount.toString();
    // TODO(Unknown): Maybe turn this into an attribute of the widget to prevent calling this
    //                for every conversation
    final width = MediaQuery.of(context).size.width - 24 - 70;

    final showTimestamp = widget.lastChangeTimestamp != timestampNever;
    final showBadge = widget.unreadCount > 0;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          AvatarWrapper(
            radius: 35,
            avatarUrl: widget.avatarUrl,
            altText: widget.name,
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
                        widget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      _buildLastMessageBody(),
                      Visibility(
                        visible: showBadge,
                        child: const Spacer(),
                      ),
                      Visibility(
                        visible: widget.unreadCount > 0,
                        child: Badge(
                          badgeContent: Text(badgeText),
                          badgeColor: bubbleColorSent,
                        ),
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
