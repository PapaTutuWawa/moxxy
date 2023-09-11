import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.cornerRadius,
    this.errorText,
    this.labelText,
    this.hintText,
    this.hintTextColor,
    this.suffix,
    this.suffixText,
    this.topWidget,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.controller,
    this.onChanged,
    this.isDense = false,
    this.contentPadding = textfieldPaddingRegular,
    this.enableIMEFeatures = true,
    this.backgroundColor,
    this.textColor,
    this.enableBoxShadow = false,
    this.borderColor,
    this.borderWidth,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.onTap,
    this.focusNode,
    this.fontSize,
    super.key,
  });
  final double cornerRadius;
  final String? errorText;
  final String? labelText;
  final String? hintText;
  final Widget? suffix;
  final String? suffixText;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final Widget? topWidget;
  final EdgeInsetsGeometry contentPadding;
  final bool enabled;
  final bool obscureText;
  final bool isDense;
  final bool enableIMEFeatures; // suggestions and autocorrect
  final bool enableBoxShadow;
  final int maxLines;
  final int minLines;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintTextColor;
  final double? borderWidth;
  final Color? borderColor;
  final double? fontSize;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final void Function()? onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final style = textColor != null
        ? TextStyle(
            color: textColor,
            fontSize: fontSize,
          )
        : null;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            color: backgroundColor,
            boxShadow:
                enableBoxShadow ? const [BoxShadow(blurRadius: 6)] : null,
            border: borderWidth != null && borderColor != null
                ? Border.all(
                    color: borderColor!,
                    width: borderWidth!,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topWidget != null) topWidget!,
              TextField(
                maxLines: maxLines,
                minLines: minLines,
                obscureText: obscureText,
                enabled: enabled,
                controller: controller,
                onChanged: onChanged,
                enableSuggestions: enableIMEFeatures,
                autocorrect: enableIMEFeatures,
                style: style,
                onTap: onTap,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  border: InputBorder.none,
                  contentPadding: contentPadding,
                  suffixIcon: suffixIcon,
                  suffix: suffix,
                  suffixText: suffixText,
                  isDense: isDense,
                  labelStyle: style,
                  suffixStyle: style,
                  hintStyle: TextStyle(
                    color: hintTextColor,
                    fontSize: fontSize,
                  ),
                  prefixIcon: prefixIcon,
                  prefixIconConstraints: prefixIconConstraints,
                  suffixIconConstraints: suffixIconConstraints,
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: errorText != null,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorText ?? '',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
