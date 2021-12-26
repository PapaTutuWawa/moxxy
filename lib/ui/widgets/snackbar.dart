import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

class PermanentSnackBar extends StatefulWidget {
  final String text;
  final String actionText;
  final void Function() onPressed;

  PermanentSnackBar({ required this.text, required this.actionText, required this.onPressed });
  
  @override
  _PermanentSnackBarState createState() => _PermanentSnackBarState(text: this.text, actionText: this.actionText, onPressed: this.onPressed);
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

    this._controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this
    )..forward();
    this._animation = Tween(
      begin: Offset(0.0, 1.0),
      end: Offset.zero
    ).animate(CurvedAnimation(
        parent: this._controller!,
        curve: Curves.easeOutCubic
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: this._animation!,
      child: Container(
        color: PRIMARY_COLOR,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(this.text),
              Spacer(),
              TextButton(
                child: Text(
                  this.actionText,
                  style: TextStyle(
                    color: Colors.white
                  )
                ),
                onPressed: this.onPressed
              )
            ]
          )
        )
      )
    );
  }
}
