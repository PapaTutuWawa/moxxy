import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';

const _bubbleBottomIconSize = fontsizeSubbody * 1.5;

class MessageBubbleBottom extends StatefulWidget {
  const MessageBubbleBottom(this.message, this.sent, { super.key });
  final Message message;
  final bool sent;

  @override
  MessageBubbleBottomState createState() => MessageBubbleBottomState();
}

class MessageBubbleBottomState extends State<MessageBubbleBottom> {
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

  bool _showBlueCheckmarks() {
    return widget.sent && widget.message.displayed;
  }

  bool _showCheckmarks() {
    return widget.sent &&
            widget.message.received &&
            !widget.message.displayed;
  }

  bool _showCheckmark() {
    return widget.sent &&
            widget.message.acked &&
            !widget.message.received &&
            !widget.message.displayed;
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            widget.message.isMedia && widget.message.mediaSize != null ?
              '${fileSizeToString(widget.message.mediaSize!)} • $_timestampString' :
              _timestampString,
            style: const TextStyle(
              fontSize: fontsizeSubbody,
              color: Color(0xffddfdfd),
            ),
          ),
        ),
        ...widget.message.isEdited ? [
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              Icons.edit,
              size: _bubbleBottomIconSize,
            ),
          ),
        ] : [],
        ...widget.message.encrypted ? [
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              Icons.lock,
              size: _bubbleBottomIconSize,
            ),
          ),
        ] : [],
        ...widget.message.hasError ? [
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              Icons.info_outline,
              size: _bubbleBottomIconSize,
              color: Colors.red,
            ),
          ),
        ] : [],
        ...widget.message.hasWarning ? [
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              Icons.warning,
              size: _bubbleBottomIconSize,
              color: Colors.yellow,
            ),
          ),
        ] : [],
        ..._showCheckmark() ? [
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(
                Icons.done,
                size: _bubbleBottomIconSize,
              ),
            ),
          ] : [],
        ..._showCheckmarks() ? [
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(
                Icons.done_all,
                size: _bubbleBottomIconSize,
              ),
            ),
          ] : [],
        ..._showBlueCheckmarks() ? [
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(
                Icons.done_all,
                size: _bubbleBottomIconSize,
                color: Colors.blue.shade700,
              ),
            ),
          ] : [],
      ],
    );
  }
}
