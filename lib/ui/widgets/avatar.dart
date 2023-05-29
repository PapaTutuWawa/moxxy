import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/service/avatars.dart';
import 'package:moxxyv2/ui/theme.dart';

class AvatarWrapper extends StatelessWidget {
  const AvatarWrapper({
    required this.radius,
    this.avatarUrl,
    this.altText,
    this.altIcon,
    this.onTapFunction,
    this.showEditButton = false,
    super.key,
  })  : assert(
          avatarUrl != null ||
              (avatarUrl == null || avatarUrl == '') &&
                  (altText != null && altText != '' || altIcon != null),
          'avatarUrl and either altText or altIcon must be set',
        ),
        assert(
          showEditButton ? onTapFunction != null : true,
          'If the edit button is shown, then a onTap handler must be set',
        );
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
          color: Theme.of(context)
              .extension<MoxxyThemeData>()!
              .profileFallbackTextColor,
        ),
      );
    }

    return Icon(
      altIcon,
      size: radius,
      color: Theme.of(context)
          .extension<MoxxyThemeData>()!
          .profileFallbackTextColor,
    );
  }

  /// Either display the alt or the actual image
  Widget _avatarWrapper(BuildContext context) {
    final useAlt = avatarUrl == null || avatarUrl == '';

    return CircleAvatar(
      backgroundColor: Theme.of(context)
          .extension<MoxxyThemeData>()!
          .profileFallbackBackgroundColor,
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
              padding: EdgeInsets.all((3 / 35) * radius),
              child: Icon(
                Icons.edit,
                size: (2 / 4) * radius,
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
      child:
          showEditButton ? _withEditButton(context) : _avatarWrapper(context),
    );
  }
}

class CachingXMPPAvatar extends StatefulWidget {
  const CachingXMPPAvatar({
    required this.jid,
    required this.altText,
    required this.radius,
    required this.hasContactId,
    this.shouldRequest = true,
    this.hash,
    this.path,
    super.key,
  });

  /// The JID of the entity.
  final String jid;

  /// The hash of the JID's avatar or null, if we don't know of an avatar.
  final String? hash;

  /// The alt-text, if [path] is null.
  final String altText;
  
  /// The (potentially null) path to the avatar image.
  final String? path;

  /// The radius of the avatar widget.
  final double radius;

  /// Flag indicating whether the conversation has a contactId != null.
  final bool hasContactId;

  /// Flag indicating whether a request for the avatar should happen or not.
  final bool shouldRequest;
  
  @override
  CachingXMPPAvatarState createState() => CachingXMPPAvatarState();
}

class CachingXMPPAvatarState extends State<CachingXMPPAvatar> {
  void _performRequest() {
    // Only request the avatar if we don't have a contact integration avatar already.
    if (!GetIt.I.get<PreferencesBloc>().state.enableContactIntegration || !widget.hasContactId) {
      GetIt.I.get<UIAvatarsService>().requestAvatarIfRequired(
        widget.jid,
        widget.hash,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    if (!widget.shouldRequest) return;

    _performRequest();
  }

  @override
  void didUpdateWidget(CachingXMPPAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldRequest && !oldWidget.shouldRequest) {
      _performRequest();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AvatarWrapper(
      avatarUrl: widget.path,
      altText: widget.altText,
      radius: widget.radius,
    );
  }
}
