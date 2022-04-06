import "dart:io";
import "package:flutter/material.dart";

class AvatarWrapper extends StatelessWidget {
  final String? avatarUrl;
  final Widget? alt;
  final IconData? altIcon;
  final double radius;
  final bool showEditButton;
  final void Function()? onTapFunction;

  AvatarWrapper({ required this.radius, this.avatarUrl, this.alt, this.altIcon, this.onTapFunction, this.showEditButton = false, Key? key }) : super(key: key) {
    assert(avatarUrl != null || (avatarUrl == null || avatarUrl == "") && (alt != null || altIcon != null));
    assert(showEditButton ? onTapFunction != null : true);
  }
  
  Widget _constructAlt() {
    if (alt != null) {
      return alt!;
    }

    return Icon(
      altIcon,
      size: radius * (180/110)
    );
  }

  /// Either display the alt or the actual image
  Widget _avatarWrapper() {
    bool useAlt = avatarUrl == null || avatarUrl == "";
    
    return CircleAvatar(
      backgroundColor: Colors.grey[800]!,
      child: useAlt ? _constructAlt() : null,
      backgroundImage: !useAlt ? FileImage(File(avatarUrl!)) : null,
      radius: radius
    );
  }

  Widget _withEditButton() {
    return Stack(
      children: [
        _avatarWrapper(),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle
            ),
            child: Padding(
              padding: EdgeInsets.all((3/35) * radius),
              child: Icon(
                Icons.edit,
                size: (2/4) * radius
              )
            )
          )
        )
      ]
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapFunction,
      child: showEditButton ? _withEditButton() : _avatarWrapper()
    );
  }
}
