import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _bubbleBottomIconSize = fontsizeSubbody * 1.5;

/// A row containing all the neccessary message metadata, like edit state, received
/// time and so on.
///
/// [message] refers to the message whose metadata we should display.
///
/// [sent] is true if the current user sent the message. If it was received (and is not
/// a carbon from a message we sent on another device), this should be false.
///
/// [shrink] indiactes whether the internal Row element should have a mainAxisSize of
/// min (true) or max (false). Defaults to false.
class MessageBubbleBottom extends StatefulWidget {
  const MessageBubbleBottom(this.message, this.sent, {
    this.shrink = false,
    super.key,
  });
  final Message message;
  final bool sent;
  final bool shrink;

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
      mainAxisSize: widget.shrink ?
        MainAxisSize.min :
        MainAxisSize.max,
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
        ...widget.message.stickerPackId != null && !GetIt.I.get<PreferencesBloc>().state.enableStickers ? [
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              PhosphorIcons.stickerBold,
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
