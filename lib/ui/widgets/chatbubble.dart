import "dart:async";
import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/shared/helpers.dart";

// TODO: Fix positioning and padding issues
//       - Images have to much padding everywhere
// TODO: The timestamp may be too light
// TODO: The timestamp is too small
import "package:flutter/material.dart";

class ChatBubble extends StatefulWidget {
  final Message message;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  const ChatBubble({
      required this.message,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth,
      Key? key
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _ChatBubbleState createState() => _ChatBubbleState(
      message: message,
      sentBySelf: sentBySelf,
      closerTogether: closerTogether,
      between: between,
      start: start,
      end: end,
      maxWidth: maxWidth
  );
}

class _ChatBubbleState extends State<ChatBubble> {
  final Message message;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  late String _timestampString;
  late Timer? _updateTimer;

  _ChatBubbleState({
      required this.message,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth
  }) {
    // Different name for now to prevent possible shadowing issues
    final _now = DateTime.now().millisecondsSinceEpoch;
    _timestampString = formatMessageTimestamp(message.timestamp, _now);

    // Only start the timer if neccessary
    if (_now - message.timestamp <= 15 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          setState(() {
              final now = DateTime.now().millisecondsSinceEpoch;
              _timestampString = formatMessageTimestamp(message.timestamp, now);

              if (now - message.timestamp > 15 * Duration.millisecondsPerMinute) {
                _updateTimer!.cancel();
              }
          });
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

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: !sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      topRight: sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      bottomLeft: !sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
      bottomRight: sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge
    );
  }
  BorderRadius _getBorderRadiusBottom() {
    return BorderRadius.only(
      bottomLeft: !sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
      bottomRight: sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge
    );
  }

  
  Widget _buildBody() {
    if (message.isMedia) {
      if (message.mediaUrl != null) {
        return _renderImage();
      } else {
        // TODO: Put a spinner here
        // TODO: PUt a button here if the user is not in our roster
      }
    }

    return _renderText();
  }

  Widget _renderImage() {
    return IntrinsicWidth(child: Stack(
        children: [
          ClipRRect(
            borderRadius: _getBorderRadius(),
            child: Image.file(
              File(message.mediaUrl!)
            )
          ),
          Positioned(
            bottom: 0,
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                borderRadius: _getBorderRadiusBottom(),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black12,
                    Colors.black54
                  ]
                )
              )
            )
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 3.0,
                    right: 6.0
                  ),
                  child: Text(
                    _timestampString,
                    style: const TextStyle(
                      fontSize: fontsizeSubbody,
                      color: Color(0xffbdbdbd)
                    )
                  )
                ) 
              ]
            )
          ) 
        ]
    ));
  }
  
  Widget _renderText() {
    return IntrinsicWidth(child: Column(
        children: [
          Text(
            message.body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: fontsizeBody
            )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Text(
                  _timestampString,
                  style: const TextStyle(
                    fontSize: fontsizeSubbody,
                    color: Color(0xffbdbdbd)
                  )
                )
              ) 
            ]
          )
        ]
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: !sentBySelf ? 8.0 : 0.0, // Conditional
        right: sentBySelf ? 8.0 : 0.0,
        top: 1.0,
        bottom: closerTogether ? 1.0 : 8.0
      ),
      child: Row(
        mainAxisAlignment: sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth
            ),
            decoration: BoxDecoration(
              color: (message.isMedia && message.mediaUrl != null) ? null : (sentBySelf ? bubbleColorSent : bubbleColorReceived),
              borderRadius: _getBorderRadius()
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildBody()
            )
          )
        ]
      )
    );
  }
}
