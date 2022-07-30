import 'dart:ui';
import 'package:flutter/material.dart';

class DateBubble extends StatelessWidget {

  const DateBubble(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          color: Theme.of(context).backgroundColor.withAlpha(180),
          boxShadow: const [BoxShadow(blurRadius: 6)],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          child: Text(value)
        ),
      ),
    );
  }
}
