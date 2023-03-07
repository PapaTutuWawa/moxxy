import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/theme.dart';

/// This Widget is used to show that a message has been quoted.
class QuoteBaseWidget extends StatelessWidget {
  /// [message]: The message used to quote
  /// [resetQuotedMessage]: Function to reset the quoted message
  const QuoteBaseWidget(
    this.message,
    this.child,
    this.sent, {
    this.resetQuotedMessage,
    super.key,
  });
  final Message message;
  final Widget child;
  final bool sent;
  final void Function()? resetQuotedMessage;

  Color _getColor(BuildContext context) {
    if (resetQuotedMessage != null) {
      return Theme.of(context)
          .extension<MoxxyThemeData>()!
          .bubbleQuoteInTextFieldColor;
    }

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
      child: ClipRRect(
        borderRadius: const BorderRadius.all(radiusLarge),
        child: Material(
          color: _getColor(context),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white,
                  width: quoteLeftBorderWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
                if (resetQuotedMessage != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: resetQuotedMessage,
                      icon: const Icon(
                        Icons.close,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
