import 'package:flutter/material.dart';

/// A row for usage in a settings UI. Similar to what settings_ui provides but without
/// the need to be wrapped in a SettingsList. Useful for when showing settings in a
/// dynamically built list.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.description,
    this.maxLines = 3,
    this.suffix,
    this.prefix,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  });
  final String title;
  final String? description;
  final int maxLines;
  final Widget? suffix;
  final Widget? prefix;
  final void Function()? onTap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
          if (prefix != null)
            prefix!,

          Expanded(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),

              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    description!,
                    maxLines: maxLines,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          if (suffix != null)
              suffix!,
          ],
        ),
      ),
    );
  }
}
