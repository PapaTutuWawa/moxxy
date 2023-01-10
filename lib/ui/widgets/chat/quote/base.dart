import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';

/// This Widget is used to show that a message has been quoted.
class QuoteBaseWidget extends StatelessWidget {
  /// [message]: The message used to quote
  /// [resetQuotedMessage]: Function to reset the quoted message
  const QuoteBaseWidget(
    this.message,
    this.child,
    this.sent,
    {
      this.resetQuotedMessage,
      super.key,
    }
  );
  final Message message;
  final Widget child;
  final bool sent;
  final void Function()? resetQuotedMessage;

  Color _getColor() {
    if (sent) {
      return bubbleColorSentQuoted;
    } else {
      return bubbleColorReceivedQuoted;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding = const EdgeInsets.only(
      left: 8 + quoteLeftBorderWidth,
      right: 8,
      top: 8,
      bottom: 8,
    );

    // Prevent a too large right padding if we have nothing to keep distance from
    if (resetQuotedMessage != null) {
      padding = padding.add(const EdgeInsets.only(right: 26));
    }
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: _getColor(),
        borderRadius: const BorderRadius.all(radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                width: quoteLeftBorderWidth,
              ),
            ),

            if (resetQuotedMessage != null)
              Positioned(
                right: 3,
                top: 3,
                child: IconButton(
                  onPressed: resetQuotedMessage,
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                  ),
                ),
              ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
