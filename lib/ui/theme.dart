import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// Helper function for quickly generating MaterialStateProperty instances that
/// only differentiate between a color for the element's disabled state and for all
/// other states.
MaterialStateProperty<Color> _makeEnabledDisabledProperty(Color enabled, Color disabled) {
  return MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) return disabled;
    return enabled;
  });
}

// NOTE: Inspired by syphon's code: https://github.com/syphon-org/syphon/blob/dev/lib/global/themes.dart
ThemeData getThemeData(BuildContext context, Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    backgroundColor: const Color(0xff303030),

    // NOTE: Mainly for the SettingsSection
    colorScheme: brightness == Brightness.dark ?
      const ColorScheme.dark(secondary: primaryColor) :
      const ColorScheme.light(secondary: primaryColor),

    // UI elements
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _makeEnabledDisabledProperty(Colors.white, textColorDisabled),
        backgroundColor: _makeEnabledDisabledProperty(primaryColor, primaryColorDisabled),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        primary: primaryColor,
      ),
    ),
    checkboxTheme: CheckboxTheme.of(context).copyWith(
      fillColor: MaterialStateProperty.all(primaryColor),
    ),
    switchTheme: SwitchTheme.of(context).copyWith(
      trackColor: _makeEnabledDisabledProperty(primaryColorAlt, primaryColorDisabled),
      thumbColor: _makeEnabledDisabledProperty(primaryColor, primaryColorDisabled),
    ),
  );
}
