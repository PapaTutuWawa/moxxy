import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/theme.dart';

Color getQuoteTextColor(BuildContext context, bool insideTextField) {
  if (!insideTextField) return bubbleTextQuoteColor;

  return Theme.of(context).extension<MoxxyThemeData>()!.bubbleQuoteInTextFieldTextColor;
}
