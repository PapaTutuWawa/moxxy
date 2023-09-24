import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/theme.dart';

/// Figures out the best text color for quotes. [context] is the surrounding
/// BuildContext. [insideTextField] is true if the quote is used as a widget inside
/// the TextField.
Color getQuoteTextColor(BuildContext context, bool insideTextField) {
  if (!insideTextField) return bubbleTextQuoteColor;

  return Theme.of(context)
      .extension<MoxxyThemeData>()!
      .bubbleQuoteInTextFieldTextColor;
}
