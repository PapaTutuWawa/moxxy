import "dart:ui";
import "package:flutter/material.dart";

class AvatarWrapper extends StatelessWidget {
  final String? avatarUrl;
  final String? altText;
  final double radius;
  final bool showEditButton;
  final void Function()? onTapFunction;

  AvatarWrapper({ required this.radius, this.avatarUrl, this.altText, this.onTapFunction, this.showEditButton = false }) {
    assert(this.avatarUrl != null || (this.avatarUrl == null || this.avatarUrl == "") && this.altText != null);
    assert(this.showEditButton ? this.onTapFunction != null : true);
  }

  /* Either display the altText or the actual image */
  Widget _avatarWrapper() {
    if (this.avatarUrl != null && this.avatarUrl != "") {
      return CircleAvatar(
        // TODO
        backgroundImage: NetworkImage(this.avatarUrl!),
        radius: this.radius
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Text(this.altText!),
        radius: radius
      );
    }
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
              padding: EdgeInsets.all(3.0),
              child: Icon(
                Icons.edit,
                size: 16.0
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
