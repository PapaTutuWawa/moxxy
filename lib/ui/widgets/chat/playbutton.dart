import "package:flutter/material.dart";

class PlayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black45
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.play_arrow,
          size: 64.0
        )
      )
    );
  }
}
