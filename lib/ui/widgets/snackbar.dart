import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

// TODO(PapaTutuWawa): Remove
class PermanentSnackBar extends StatefulWidget {
  // TODO(Unknown): Remove linter ignore
  // ignore: prefer_const_constructors_in_immutables
  PermanentSnackBar(
      {required this.text,
      required this.actionText,
      required this.onPressed,
      super.key});
  final String text;
  final String actionText;
  final void Function() onPressed;

  @override
  // ignore: no_logic_in_create_state
  PermanentSnackBarState createState() => PermanentSnackBarState(
      text: text, actionText: actionText, onPressed: onPressed);
}

class PermanentSnackBarState extends State<PermanentSnackBar>
    with TickerProviderStateMixin {
  PermanentSnackBarState(
      {required this.text, required this.actionText, required this.onPressed});
  final String text;
  final String actionText;
  final void Function() onPressed;

  // ignore: use_late_for_private_fields_and_variables
  AnimationController? _controller;
  // ignore: use_late_for_private_fields_and_variables
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..forward();
    _animation = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation!,
      child: ColoredBox(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(text),
              const Spacer(),
              TextButton(
                onPressed: onPressed,
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
