import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

/// This Widget is used to show that a message has been quoted.
class QuoteBaseWidget extends StatelessWidget {
  final Message message;
  final Widget child;
  final void Function()? resetQuotedMessage;

  /// [message]: The message used to quote
  /// [resetQuotedMessage]: Function to reset the quoted message
  const QuoteBaseWidget(
    this.message,
    this.child,
    {
      this.resetQuotedMessage,
      Key? key
    }
  ) : super(key: key);

  Color _getColor() {
    if (message.sent) {
      return bubbleColorSentQuoted;
    } else {
      return bubbleColorReceivedQuoted;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const quoteLeftBorderWidth = 7.0;
    EdgeInsetsGeometry padding = EdgeInsets.only(
      left: 8.0 + quoteLeftBorderWidth,
      right: 8.0,
      top: 8.0,
      bottom: 8.0
    );

    // Prevent a too large right padding if we have nothing to keep distance from
    if (resetQuotedMessage != null) {
      padding = padding.add(const EdgeInsets.only(right: 26.0));
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: _getColor(),
          borderRadius: const BorderRadius.all(radiusLarge)
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0.0,
              top: 0.0,
              bottom: 0.0,
              child: Container(
                color: Colors.white,
                width: quoteLeftBorderWidth,
              )
            ),
            ...(
              resetQuotedMessage != null ? [Positioned(
                right: 3.0,
                top: 3.0,
                child: InkWell(
                  onTap: resetQuotedMessage,
                  child: const Icon(
                    Icons.close,
                    size: 24.0
                  )
                )
              )] : []
            ),
            Padding(
              padding: padding,
              child: child
            ),
          ]
        )
      )
    );
  }
}
