import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/service/avatars.dart';
import 'package:moxxyv2/ui/theme.dart';

class CachingXMPPAvatar extends StatefulWidget {
  const CachingXMPPAvatar({
    required this.jid,
    required this.radius,
    required this.hasContactId,
    required this.isGroupchat,
    this.altIcon,
    this.shouldRequest = true,
    this.ownAvatar = false,
    this.hash,
    this.path,
    this.onTap,
    super.key,
  });

  static Widget self({
    required double radius,
    VoidCallback? onTap,
  }) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      buildWhen: (prev, next) => prev.avatarPath != next.avatarPath,
      builder: (context, state) {
        return CachingXMPPAvatar(
          radius: radius,
          path: state.avatarPath,
          altIcon: Icons.person,
          hasContactId: false,
          isGroupchat: false,
          jid: state.jid,
          ownAvatar: true,
          onTap: onTap,
        );
      },
    );
  }

  /// The JID of the entity.
  final String jid;

  /// The hash of the JID's avatar or null, if we don't know of an avatar.
  final String? hash;

  /// The (potentially null) path to the avatar image.
  final String? path;

  /// The radius of the avatar widget.
  final double radius;

  /// Flag indicating that the avatar is a groupchat avatar.
  final bool isGroupchat;

  /// Flag indicating whether the conversation has a contactId != null.
  final bool hasContactId;

  /// Flag indicating whether a request for the avatar should happen or not.
  final bool shouldRequest;

  /// Alt-icon, if [path] is null.
  final IconData? altIcon;

  /// Flag indicating whether this avatar is our own avatar.
  final bool ownAvatar;

  /// If set, called when the avatar has been tapped.
  final VoidCallback? onTap;

  @override
  CachingXMPPAvatarState createState() => CachingXMPPAvatarState();
}

class CachingXMPPAvatarState extends State<CachingXMPPAvatar> {
  void _performRequest() {
    // Only request the avatar if we don't have a contact integration avatar already.
    if (!GetIt.I.get<PreferencesBloc>().state.enableContactIntegration ||
        !widget.hasContactId) {
      GetIt.I.get<UIAvatarsService>().requestAvatarIfRequired(
            widget.jid,
            widget.hash,
            widget.ownAvatar,
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

    // TODO(Unknown): Remove once we can query groupchat avatars.
    if (widget.isGroupchat) {
      return;
    }

    if (widget.shouldRequest && !oldWidget.shouldRequest) {
      _performRequest();
    }
  }

  Widget _buildChild() {
    if (widget.altIcon != null) {
      return Icon(
        widget.altIcon,
        // NOTE: 62/87 is 2*31/87, of which 31/87 has been pixel measured from how it was
        // before this size attribute has been set. The multiplication with 2 just makes
        // it look better.
        size: widget.radius * (62 / 87),
      );
    }

    assert(
      widget.jid.length >= 2,
      '${widget.jid} must be longer longer than 1 character',
    );
    return Text(widget.jid.substring(0, 2).toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: Material(
          color: Colors.transparent,
          child: StreamBuilder<AvatarUpdatedEvent>(
            stream: GetIt.I
                .get<UIAvatarsService>()
                .stream
                .where((event) => event.jid == widget.jid),
            builder: (context, snapshot) {
              final path = snapshot.data?.path ?? widget.path;
              // TODO(Unknown): Remove once we can handle groupchat avatars
              if (path == null || widget.isGroupchat) {
                return Ink(
                  color: Theme.of(context)
                      .extension<MoxxyThemeData>()!
                      .profileFallbackBackgroundColor,
                  child: InkWell(
                    onTap: widget.onTap,
                    child: Center(
                      child: _buildChild(),
                    ),
                  ),
                );
              } else {
                return Ink.image(
                  image: FileImage(File(path)),
                  fit: BoxFit.cover,
                  child: InkWell(
                    onTap: widget.onTap,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
