import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

class CustomTextField extends StatelessWidget {
  final double cornerRadius;
  final String? errorText;
  final String? labelText;
  final String? hintText;
  final Widget? suffix;
  final String? suffixText;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry contentPadding;
  final bool enabled;
  final bool obscureText;
  final bool isDense;
  final bool enableIMEFeatures; // suggestions and autocorrect
  final int maxLines;
  final int minLines;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
      required this.cornerRadius,
      this.errorText,
      this.labelText,
      this.hintText,
      this.suffix,
      this.suffixText,
      this.suffixIcon,
      this.enabled = true,
      this.obscureText = false,
      this.maxLines = 1,
      this.minLines = 1,
      this.controller,
      this.onChanged,
      this.isDense = false,
      this.contentPadding = textfieldPaddingRegular,
      this.enableIMEFeatures = true,
      Key? key
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(
              width: 1,
              color: Colors.purple
            )
          ),
          child: TextField(
            maxLines: maxLines,
            minLines: minLines,
            obscureText: obscureText,
            enabled: enabled,
            controller: controller,
            onChanged: onChanged,
            enableSuggestions: enableIMEFeatures,
            autocorrect: enableIMEFeatures,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: contentPadding,
              suffixIcon: suffixIcon,
              suffix: suffix,
              suffixText: suffixText,
              isDense: isDense
            )
          )
        ),
        Visibility(
          visible: errorText != null,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorText ?? "",
                style: const TextStyle(
                  color: Colors.red
                )
              )
            )
          )
        ) 
      ]
    );
  }
}
