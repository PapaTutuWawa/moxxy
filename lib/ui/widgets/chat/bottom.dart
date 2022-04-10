import "dart:async";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/shared/models/message.dart";

import "package:flutter/material.dart";

class MessageBubbleBottom extends StatefulWidget {
  final Message message;

  const MessageBubbleBottom(this.message, { Key? key }): super(key: key);

  @override
  _MessageBubbleBottomState createState() => _MessageBubbleBottomState();
}

class _MessageBubbleBottomState extends State<MessageBubbleBottom> {
  late String _timestampString;
  late Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    // Different name for now to prevent possible shadowing issues
    final _now = DateTime.now().millisecondsSinceEpoch;
    _timestampString = formatMessageTimestamp(widget.message.timestamp, _now);

    // Only start the timer if neccessary
    if (_now - widget.message.timestamp <= 15 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          setState(() {
              final now = DateTime.now().millisecondsSinceEpoch;
              _timestampString = formatMessageTimestamp(widget.message.timestamp, now);

              if (now - widget.message.timestamp > 15 * Duration.millisecondsPerMinute) {
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
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            _timestampString,
            style: const TextStyle(
              fontSize: fontsizeSubbody,
              color: Color(0xffddfdfd)
            )
          )
        ),
        ...(widget.message.sent && widget.message.acked && !widget.message.received && !widget.message.displayed ? [
            const Padding(
              padding: EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done,
                size: fontsizeSubbody * 2
              )
            )
          ] : []),
        ...(widget.message.sent && widget.message.received && !widget.message.displayed ? [
            const Padding(
              padding: EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2
              )
            )
          ] : []),
        ...(widget.message.sent && widget.message.displayed ? [
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2,
                color: Colors.blue.shade700
              )
            )
          ] : [])
      ]
    );
  }
}
