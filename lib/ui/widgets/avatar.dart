import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/theme.dart';

class AvatarWrapper extends StatelessWidget {
  const AvatarWrapper({ required this.radius, this.avatarUrl, this.altText, this.altIcon, this.onTapFunction, this.showEditButton = false, super.key })
    : assert(avatarUrl != null || (avatarUrl == null || avatarUrl == '') && (altText != null && altText != '' || altIcon != null), 'avatarUrl and either altText or altIcon must be set'),
      assert(showEditButton ? onTapFunction != null : true, 'If the edit button is shown, then a onTap handler must be set');
  final String? avatarUrl;
  final String? altText;
  final IconData? altIcon;
  final double radius;
  final bool showEditButton;
  final void Function()? onTapFunction;
  
  Widget _constructAlt(BuildContext context) {
    if (altText != null) {
      return Text(
        avatarAltText(altText!),
        style: TextStyle(
          fontSize: radius * 0.8,
          color: Theme.of(context).extension<MoxxyThemeData>()!.profileFallbackTextColor,
        ),
      );
    }

    return Icon(
      altIcon,
      size: radius,
      color: Theme.of(context).extension<MoxxyThemeData>()!.profileFallbackTextColor,
    );
  }

  /// Either display the alt or the actual image
  Widget _avatarWrapper(BuildContext context) {
    final useAlt = avatarUrl == null || avatarUrl == '';
    
    return CircleAvatar(
      backgroundColor: Theme.of(context).extension<MoxxyThemeData>()!.profileFallbackBackgroundColor,
      backgroundImage: !useAlt ? FileImage(File(avatarUrl!)) : null,
      radius: radius,
      child: useAlt ? _constructAlt(context) : null,
    );
  }

  Widget _withEditButton(BuildContext context) {
    return Stack(
      children: [
        _avatarWrapper(context),
        Positioned(
          bottom: 0,
          right: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all((3/35) * radius),
              child: Icon(
                Icons.edit,
                size: (2/4) * radius,
              ),
            ),
          ),
        )
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapFunction,
      child: showEditButton ?
        _withEditButton(context) :
        _avatarWrapper(context),
    );
  }
}
