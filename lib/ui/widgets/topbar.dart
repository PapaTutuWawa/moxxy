import "package:moxxyv2/ui/widgets/avatar.dart";

import "package:flutter/material.dart";

/// Provides a Signal-like topbar without borders or anything else
class BorderlessTopbar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> children;

  const BorderlessTopbar({ required this.children, Key? key }) : super(key: key);

  BorderlessTopbar.justBackButton({Key? key}) : children = [
    const BackButton()
  ], super(key: key);
  
  /// A simple borderless topbar that displays just the back button (if wanted) and a
  /// Text() title.
  BorderlessTopbar.simple({ required String title , List<Widget>? extra, bool showBackButton = true, Key? key }) : children = [
    Visibility(
      child: const BackButton(),
      visible: showBackButton
    ),
    Text(
      title,
      style: const TextStyle(
        fontSize: 20
      )
    ),
    ...(extra ?? [])
  ], super(key: key);

  /// Displays a clickable avatar and title and a back button, if wanted
  // TODO: Reuse BorderlessTopbar.simple
  BorderlessTopbar.avatarAndName({ required AvatarWrapper avatar, required String title, void Function()? onTapFunction, List<Widget>? extra, bool showBackButton = true, Key? key }) : children = [
    Visibility(
      child: const BackButton(),
      visible: showBackButton
    ),
    Center(
      child: InkWell(
        child: Row(
          children: [
            avatar,
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20
                )
              )
            )
          ]
        ),
        onTap: onTapFunction
      )
    ),
    const Spacer(),
    ...(extra ?? [])
  ], super(key: key);

  @override
  final Size preferredSize = const Size.fromHeight(60);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: children
        )
      )
    );
  }
}
