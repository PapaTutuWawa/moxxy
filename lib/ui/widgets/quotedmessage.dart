import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

/// This Widget is used to show that a message has been quoted.
class QuotedMessageWidget extends StatelessWidget {
  final Message message;
  final void Function() resetQuotedMessage;

  /// [message]: The message used to quote
  /// [resetQuotedMessage]: Function to reset the quoted message
  const QuotedMessageWidget({
      required this.message,
      required this.resetQuotedMessage,
      Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const quoteLeftBorderWidth = 7.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: const BoxDecoration(
          color: bubbleColorReceived,
          borderRadius: BorderRadius.all(radiusLarge)
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
            Positioned(
              right: 3.0,
              top: 3.0,
              child: InkWell(
                onTap: resetQuotedMessage,
                child: Icon(
                  Icons.close,
                  size: 24.0
                )
              )
            ),
            Padding(
              padding: const EdgeInsets.all(8.0).add(const EdgeInsets.only(left: quoteLeftBorderWidth, right: 26.0)),
              child: Text(message.body)
            ),
          ]
        )
      )
    );
  }
}
