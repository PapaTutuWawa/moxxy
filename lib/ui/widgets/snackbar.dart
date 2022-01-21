import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

class PermanentSnackBar extends StatefulWidget {
  final String text;
  final String actionText;
  final void Function() onPressed;

  // TODO: Remove linter ignore
  // ignore: prefer_const_constructors_in_immutables
  PermanentSnackBar({ required this.text, required this.actionText, required this.onPressed, Key? key }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _PermanentSnackBarState createState() => _PermanentSnackBarState(text: text, actionText: actionText, onPressed: onPressed);
}

class _PermanentSnackBarState extends State<PermanentSnackBar> with TickerProviderStateMixin {
  final String text;
  final String actionText;
  final void Function() onPressed;

  AnimationController? _controller;
  Animation<Offset>? _animation;

  _PermanentSnackBarState({ required this.text, required this.actionText, required this.onPressed });

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this
    )..forward();
    _animation = Tween(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero
    ).animate(CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOutCubic
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation!,
      child: Container(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(text),
              const Spacer(),
              TextButton(
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: Colors.white
                  )
                ),
                onPressed: onPressed
              )
            ]
          )
        )
      )
    );
  }
}
