import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// The preferred height of the borderless topbar.
const topbarPreferredHeight = 60.0;

class BorderlessTopbar extends StatelessWidget implements PreferredSizeWidget {
  const BorderlessTopbar({
    required this.children,
    this.showBackButton = true,
    this.backButtonWidget = const BackButton(),
    super.key,
  }) : preferredSize = const Size.fromHeight(topbarPreferredHeight);

  /// A wrapper around the default constructor for situations where you only want to display
  /// a title and maybe a trailing widget.
  BorderlessTopbar.title(
    String title, {
    bool showBackButton = true,
    Widget? trailing,
    Widget? backButtonWidget,
    Key? key,
  }) : this(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: fontsizeAppbar,
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
          backButtonWidget: backButtonWidget ?? const BackButton(),
          showBackButton: showBackButton,
          key: key,
        );

  /// Flag whether or not to show the backbutton.
  final bool showBackButton;

  /// The widget that is the back button. Useful for disabling it in certain situations.
  final Widget backButtonWidget;

  /// The children to show in the row of the topbar.
  final List<Widget> children;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.all(8),
                child: backButtonWidget,
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}
