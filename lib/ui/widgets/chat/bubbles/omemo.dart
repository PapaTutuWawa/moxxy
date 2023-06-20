import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

class OmemoBubble extends StatelessWidget {
  const OmemoBubble({
    required this.text,
    required this.onTap,
    super.key,
  });

  /// The text to display in the bubble.
  final String text;

  /// Callback for tapping the message.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Material(
          color: bubbleColorNewDevice,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
