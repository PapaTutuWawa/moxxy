import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// A theme extension for Moxxy specific colors.
@immutable
class MoxxyThemeData extends ThemeExtension<MoxxyThemeData> {
  const MoxxyThemeData({
    required this.conversationTextFieldColor,
    required this.profileFallbackBackgroundColor,
    required this.profileFallbackTextColor,
    required this.bubbleQuoteInTextFieldColor,
    required this.bubbleQuoteInTextFieldTextColor,
    required this.conversationTextFieldHintTextColor,
    required this.conversationTextFieldTextColor,
    required this.conversationOverlayTextColor,
  });

  /// The color of the conversation TextField
  final Color conversationTextFieldColor;

  /// The color of the background of a user with no avatar
  final Color profileFallbackBackgroundColor;

  /// The text color of a user with no avatar
  final Color profileFallbackTextColor;

  /// The color of a quote bubble displayed inside the TextField
  final Color bubbleQuoteInTextFieldColor;

  /// The color of text inside a quote bubble inside the TextField
  final Color bubbleQuoteInTextFieldTextColor;

  /// The color of the hint text inside the TextField of the ConversationPage
  final Color conversationTextFieldHintTextColor;

  /// The regular text color of the message TextField on the ConversationPage
  final Color conversationTextFieldTextColor;

  /// The text color of the buttons in the overlay of the ConversationPage
  final Color conversationOverlayTextColor;

  @override
  MoxxyThemeData copyWith({
    Color? conversationTextFieldColor,
    Color? profileFallbackBackgroundColor,
    Color? profileFallbackTextColor,
    Color? bubbleQuoteInTextFieldColor,
    Color? bubbleQuoteInTextFieldTextColor,
    Color? conversationTextFieldHintTextColor,
    Color? conversationTextFieldTextColor,
    Color? conversationOverlayTextColor,
  }) {
    return MoxxyThemeData(
      conversationTextFieldColor:
          conversationTextFieldColor ?? this.conversationTextFieldColor,
      profileFallbackBackgroundColor:
          profileFallbackBackgroundColor ?? this.profileFallbackBackgroundColor,
      profileFallbackTextColor:
          profileFallbackTextColor ?? this.profileFallbackTextColor,
      bubbleQuoteInTextFieldColor:
          bubbleQuoteInTextFieldColor ?? this.bubbleQuoteInTextFieldColor,
      bubbleQuoteInTextFieldTextColor: bubbleQuoteInTextFieldTextColor ??
          this.bubbleQuoteInTextFieldTextColor,
      conversationTextFieldHintTextColor: conversationTextFieldHintTextColor ??
          this.conversationTextFieldHintTextColor,
      conversationTextFieldTextColor:
          conversationTextFieldTextColor ?? this.conversationTextFieldTextColor,
      conversationOverlayTextColor:
          conversationOverlayTextColor ?? this.conversationOverlayTextColor,
    );
  }

  @override
  MoxxyThemeData lerp(ThemeExtension<MoxxyThemeData>? other, double t) {
    return this;
  }
}

/// Helper function for quickly generating MaterialStateProperty instances that
/// only differentiate between a color for the element's disabled state and for all
/// other states.
MaterialStateProperty<Color> _makeEnabledDisabledProperty(
  Color enabled,
  Color disabled,
) {
  return MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) return disabled;
    return enabled;
  });
}

// NOTE: Inspired by syphon's code: https://github.com/syphon-org/syphon/blob/dev/lib/global/themes.dart
ThemeData getThemeData(BuildContext context, Brightness brightness) {
  return ThemeData(
    brightness: brightness,

    // NOTE: Mainly for the SettingsSection
    colorScheme: brightness == Brightness.dark
        ? const ColorScheme.dark(
            secondary: primaryColor,
            background: Color(0xff303030),
          )
        : const ColorScheme.light(
            secondary: primaryColor,
            background: Color(0xff303030),
          ),

    // UI elements
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor:
            _makeEnabledDisabledProperty(Colors.white, textColorDisabled),
        backgroundColor:
            _makeEnabledDisabledProperty(primaryColor, primaryColorDisabled),
      ),
    ),
    checkboxTheme: CheckboxTheme.of(context).copyWith(
      fillColor: MaterialStateProperty.all(primaryColor),
    ),
    switchTheme: SwitchTheme.of(context).copyWith(
      trackColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return primaryColorDisabled;
        } else if (!states.contains(MaterialState.selected)) {
          return primaryColorDisabled;
        }

        return primaryColorAlt;
      }),
      thumbColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.white;
        } else if (!states.contains(MaterialState.selected)) {
          return Colors.white;
        }

        return primaryColor;
      }),
    ),

    extensions: [
      if (brightness == Brightness.dark)
        const MoxxyThemeData(
          conversationTextFieldColor: conversationTextFieldColorDark,
          profileFallbackBackgroundColor: profileFallbackBackgroundColorDark,
          profileFallbackTextColor: profileFallbackTextColorDark,
          bubbleQuoteInTextFieldColor: bubbleQuoteInTextFieldColorDark,
          bubbleQuoteInTextFieldTextColor: bubbleQuoteInTextFieldTextColorDark,
          conversationTextFieldHintTextColor: textFieldHintTextColorDark,
          conversationTextFieldTextColor: textFieldTextColorDark,
          conversationOverlayTextColor: conversationOverlayButtonTextColor,
        )
      else
        const MoxxyThemeData(
          conversationTextFieldColor: conversationTextFieldColorLight,
          profileFallbackBackgroundColor: profileFallbackBackgroundColorLight,
          profileFallbackTextColor: profileFallbackTextColorLight,
          bubbleQuoteInTextFieldColor: bubbleQuoteInTextFieldColorLight,
          bubbleQuoteInTextFieldTextColor: bubbleQuoteInTextFieldTextColorLight,
          conversationTextFieldHintTextColor: textFieldHintTextColorLight,
          conversationTextFieldTextColor: textFieldTextColorLight,
          conversationOverlayTextColor: conversationOverlayButtonTextColor,
        ),
    ],
  );
}
