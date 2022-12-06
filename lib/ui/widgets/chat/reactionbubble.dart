import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

class ReactionBubble extends StatelessWidget {
  const ReactionBubble({
    required this.emoji,
    required this.reactions,
    required this.reactedTo,
    required this.sentBySelf,
    this.onTap,
    super.key,
  });
  final String emoji;
  final int reactions;
  final bool reactedTo;
  final bool sentBySelf;
  final void Function()? onTap;

  Color _getColor() {
    if (reactedTo) {
      return const Color(0xff007db0);
    }

    return sentBySelf ?
      bubbleColorSent :
      bubbleColorReceived;
  }
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(radiusLarge),
      child: Material(
        color: _getColor(),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '$emoji $reactions',
              style: const TextStyle(
                fontSize: 18,
              ),  
            ),
          ),
        ),
      ),
    );
  }
}
