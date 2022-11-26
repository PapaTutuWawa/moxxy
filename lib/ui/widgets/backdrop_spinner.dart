import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// A simple CircularProgressIndicator that has a semi-transparent black
/// circle around it to provide contrast to whatever is behind it.
class BackdropSpinner extends StatelessWidget {
  const BackdropSpinner({
    required this.enabled,
    super.key,
  });
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backdropBlack,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return const SizedBox();
  }
}
