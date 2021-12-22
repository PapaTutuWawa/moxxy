import 'package:flutter/material.dart';

/*
Provides a Signal-like topbar without borders or anything else
*/
class BorderlessTopbar extends StatelessWidget {
  List<Widget> children;
  bool boxShadow;

  BorderlessTopbar({ required this.children, this.boxShadow = false });
  
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
