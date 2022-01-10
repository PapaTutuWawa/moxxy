import "dart:ui";
import "dart:io";
import "package:flutter/material.dart";

class AvatarWrapper extends StatelessWidget {
  final String? avatarUrl;
  final Widget? alt;
  final IconData? altIcon;
  final double radius;
  final bool showEditButton;
  final void Function()? onTapFunction;

  AvatarWrapper({ required this.radius, this.avatarUrl, this.alt, this.altIcon, this.onTapFunction, this.showEditButton = false }) {
    assert(this.avatarUrl != null || (this.avatarUrl == null || this.avatarUrl == "") && (this.alt != null || this.altIcon != null));
    assert(this.showEditButton ? this.onTapFunction != null : true);
  }
  
  Widget _constructAlt() {
    if (this.alt != null) {
      return this.alt!;
    }

    return Icon(
      this.altIcon,
      size: this.radius * (180/110)
    );
  }

  // TODO: Remove this. This is just for UI debugging
  ImageProvider _constructImage() {
    if (this.avatarUrl!.startsWith("https://")) {
      return NetworkImage(this.avatarUrl!);
    } else {
      return FileImage(File(this.avatarUrl!));
    }
  }
  
  /* Either display the alt or the actual image */
  Widget _avatarWrapper() {
    bool useAlt = this.avatarUrl == null || this.avatarUrl == "";
    
    return CircleAvatar(
      backgroundColor: Colors.grey[800]!,
      child: useAlt ? this._constructAlt() : null,
      // TODO
      backgroundImage: !useAlt ? this._constructImage() : null,
      radius: radius
    );
  }

  Widget _withEditButton() {
    return Stack(
      children: [
        this._avatarWrapper(),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle
            ),
            child: Padding(
              padding: EdgeInsets.all((3/35) * this.radius),
              child: Icon(
                Icons.edit,
                size: (2/4) * this.radius
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
      onTap: this.onTapFunction,
      child: this.showEditButton ? this._withEditButton() : this._avatarWrapper()
    );
  }
}
