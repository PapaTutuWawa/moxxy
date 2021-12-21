import 'package:flutter/material.dart';

/*
Provides a Signal-like topbar without borders or anything else
*/
class BorderlessTopbar extends StatelessWidget {
  List<Widget> children;

  BorderlessTopbar({ required this.children });
  
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
