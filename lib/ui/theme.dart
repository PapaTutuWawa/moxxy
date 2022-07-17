import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

// NOTE: Inspired by syphon's code: https://github.com/syphon-org/syphon/blob/dev/lib/global/themes.dart
ThemeData getThemeData(Brightness brightness) {
  final onColor = brightness == Brightness.dark ? Colors.white : Colors.black;
  return ThemeData(
    primaryColor: primaryColor,
    primaryColorDark: primaryColor,
    primaryColorLight: primaryColor,
    brightness: brightness,
    /*colorScheme: ThemeData().colorScheme.copyWith(
      primary: primaryColor,
      onPrimary: onColor,
      secondary: primaryColor,
      onSecondary: onColor,
      brightness: brightness
    ),*/

    // UI
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        primary: primaryColor,
      ),
    ),
    iconTheme: IconThemeData(color: onColor), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: primaryColor),
  );
}
