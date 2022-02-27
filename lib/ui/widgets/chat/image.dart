import "dart:io";

import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

class ImageChatWidget extends StatelessWidget {
  final String path;
  final String timestamp;
  final BorderRadius radius;

  const ImageChatWidget({ required this.path, required this.timestamp, required this.radius, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: Stack(
        children: [
          ClipRRect(
            borderRadius: radius,
            child: Image.file(
              File(path)
            )
          ),
          Positioned(
            bottom: 0,
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black12,
                    Colors.black54
                  ]
                )
              )
            )
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 3.0,
                    right: 6.0
                  ),
                  child: Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: fontsizeSubbody,
                      color: Color(0xffbdbdbd)
                    )
                  )
                ) 
              ]
            )
          ) 
        ]
    ));
  }
}
