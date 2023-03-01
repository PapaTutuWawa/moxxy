import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// A section title similar to what settings_ui provides.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, { super.key });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          color: settingsSectionTitleColor,
        ),
      ),
    );
  }
}
