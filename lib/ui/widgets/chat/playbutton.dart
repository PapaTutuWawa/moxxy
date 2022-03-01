import "package:flutter/material.dart";

class PlayButton extends StatelessWidget {
  const PlayButton({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black45
      ),
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.play_arrow,
          size: 64.0
        )
      )
    );
  }
}
