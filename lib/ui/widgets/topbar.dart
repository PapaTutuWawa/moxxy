import "dart:collection";
import 'package:flutter/material.dart';

import "package:moxxyv2/ui/widgets/avatar.dart";

/*
Provides a Signal-like topbar without borders or anything else
*/
class BorderlessTopbar extends StatelessWidget implements PreferredSizeWidget {
  List<Widget> children;
  // TODO: Implement
  bool boxShadow;

  BorderlessTopbar({ required this.children, this.boxShadow = false });

  /*
   * A simple borderless topbar that displays just the back button (if wanted) and a
   * Text() title
   */
  BorderlessTopbar.simple({ required String title , List<Widget>? extra, bool showBackButton = true }) : boxShadow = false, children = [
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

  /*
   * Displays a clickable avatar and title and a back button, if wanted
   */
  // TODO: Reuse BorderlessTopbar.simple
  BorderlessTopbar.avatarAndName({ required AvatarWrapper avatar, required String title, void Function()? onTapFunction, List<Widget>? extra, bool showBackButton = true }) : boxShadow = false, children = [
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
          ),
          decoration: BoxDecoration(
            boxShadow: this.boxShadow ? [
              // TODO
              /*
              BoxShadow(
                color: Colors.black,
                offset: Offset(
                  0.0,
                  10.0
                ),
                blurRadius: 10.0,
                spreadRadius: 10.0
              )
              */
            ] : []
          )
        )
      )
    );
  }
}
