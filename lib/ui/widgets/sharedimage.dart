import 'package:flutter/material.dart';

/*
A widget to show a message that was sent within a chat
TODO: Eventually generalise to also show different kinds of sent stuff, like
      files
*/
class SharedImage extends StatelessWidget {
  ImageProvider image;

  SharedImage({ required this.image });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 75,
        width: 75,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: this.image
              )
            )
          )
        )
      )
    );
  }
}
