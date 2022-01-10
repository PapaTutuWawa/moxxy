import "package:flutter/material.dart";
import "package:moxxyv2/ui/constants.dart";

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

  CustomTextField({
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
      this.contentPadding = TEXTFIELD_PADDING_REGULAR,
      this.enableIMEFeatures = true
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(this.cornerRadius),
            border: Border.all(
              width: 1,
              color: Colors.purple
            )
          ),
          child: TextField(
            maxLines: this.maxLines,
            minLines: this.minLines,
            obscureText: this.obscureText,
            enabled: this.enabled,
            controller: this.controller,
            onChanged: this.onChanged,
            enableSuggestions: this.enableIMEFeatures,
            autocorrect: this.enableIMEFeatures,
            decoration: InputDecoration(
              labelText: this.labelText,
              hintText: this.hintText,
              border: InputBorder.none,
              contentPadding: this.contentPadding,
              suffixIcon: this.suffixIcon,
              suffix: this.suffix,
              suffixText: this.suffixText,
              isDense: this.isDense
            )
          )
        ),
        Visibility(
          visible: this.errorText != null,
          child: Padding(
            padding: EdgeInsets.all(2.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                this.errorText ?? "",
                style: TextStyle(
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
