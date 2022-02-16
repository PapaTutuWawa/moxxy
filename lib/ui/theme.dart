import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

// NOTE: Inspired by syphon's code: https://github.com/syphon-org/syphon/blob/dev/lib/global/themes.dart
ThemeData getThemeData(Brightness brightness) {
  final onColor = brightness == Brightness.dark ? Colors.white : Colors.black;
  return ThemeData(
    primaryColor: primaryColor,
    primaryColorBrightness: brightness,
    primaryColorDark: primaryColor,
    primaryColorLight: primaryColor,
    accentColor: primaryColor,
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
        primary: primaryColor
      )
    ),
    iconTheme: IconThemeData(color: onColor)
  );
}
