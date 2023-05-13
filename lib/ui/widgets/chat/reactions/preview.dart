import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/list.dart';

class ReactionsPreview extends StatelessWidget {
  const ReactionsPreview(this.message, this.sentBySelf, {super.key});

  final Message message;

  final bool sentBySelf;

  @override
  Widget build(BuildContext context) {
    if (message.reactionsPreview.isEmpty) {
      return const SizedBox();
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(textfieldRadiusRegular),
            ),
          ),
          builder: (context) {
            return ReactionList(
              message.id,
              message.conversationJid,
            );
          },
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          // TODO: Move to ui/constants.dart
          color: const Color(0xff757575),
          borderRadius: BorderRadius.only(
            topLeft: sentBySelf
              ? Radius.circular(40)
              : Radius.zero,
            topRight: sentBySelf
              ? Radius.zero
              : Radius.circular(40),
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 4,
            left: 10,
            right: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Only show 5 reactions. The last one is just for indicating that
                // there are more reactions.
                message.reactionsPreview.length == 6
                  ? message.reactionsPreview.sublist(0, 6).join(' ')
                  : message.reactionsPreview.join(' '),
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              if (message.reactionsPreview.length == 6)
              const Icon(
                Icons.more_horiz,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
