import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/service/avatars.dart';

class CachingXMPPAvatar extends StatefulWidget {
  const CachingXMPPAvatar({
    required this.jid,
    required this.radius,
    required this.hasContactId,
    this.altIcon,
    this.shouldRequest = true,
    this.ownAvatar = false,
    this.hash,
    this.path,
    this.onTap,
    super.key,
  });

  /// The JID of the entity.
  final String jid;

  /// The hash of the JID's avatar or null, if we don't know of an avatar.
  final String? hash;

  /// The (potentially null) path to the avatar image.
  final String? path;

  /// The radius of the avatar widget.
  final double radius;

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
    return InkWell(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: StreamBuilder<AvatarUpdatedEvent>(
          stream: GetIt.I
              .get<UIAvatarsService>()
              .stream
              .where((event) => event.jid == widget.jid),
          builder: (context, snapshot) {
            final path = snapshot.data?.path ?? widget.path;
            final isValidPath = path?.isNotEmpty ?? false;
            return CircleAvatar(
              backgroundImage:
                  isValidPath ? FileImage(File(widget.path!)) : null,
              child: isValidPath ? null : _buildChild(),
            );
          },
        ),
      ),
    );
  }
}
