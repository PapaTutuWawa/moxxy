import "dart:collection";

import "package:moxxyv2/ui/widgets/avatar.dart";

import "package:flutter/material.dart";

/// Provides a Signal-like topbar without borders or anything else
class BorderlessTopbar extends StatelessWidget implements PreferredSizeWidget {
  List<Widget> children;

  BorderlessTopbar({ required this.children });

  BorderlessTopbar.justBackButton() : children = [
    BackButton()
  ];
  
  /// A simple borderless topbar that displays just the back button (if wanted) and a
  /// Text() title.
  BorderlessTopbar.simple({ required String title , List<Widget>? extra, bool showBackButton = true }) : children = [
    Visibility(
      child: BackButton(),
      visible: showBackButton
    ),
    Text(
      title,
      style: TextStyle(
        fontSize: 20
      )
    ),
    ...(extra ?? [])
  ];

  /// Displays a clickable avatar and title and a back button, if wanted
  // TODO: Reuse BorderlessTopbar.simple
  BorderlessTopbar.avatarAndName({ required AvatarWrapper avatar, required String title, void Function()? onTapFunction, List<Widget>? extra, bool showBackButton = true }) : children = [
    Visibility(
      child: BackButton(),
      visible: showBackButton
    ),
    Center(
      child: InkWell(
        child: Row(
          children: [
            avatar,
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20
                )
              )
            )
          ]
        ),
        onTap: onTapFunction
      )
    ),
    Spacer(),
    ...(extra ?? [])
  ];

  @override
  final Size preferredSize = Size.fromHeight(60);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Container(
          child: Row(
            children: this.children
          )
        )
      )
    );
  }
}
