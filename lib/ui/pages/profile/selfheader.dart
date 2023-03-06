import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/own_devices_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/profile/options.dart';

class SelfProfileHeader extends StatelessWidget {
  const SelfProfileHeader(
    this.jid,
    this.avatarUrl,
    this.displayName,
    this.setAvatar, {
    super.key,
  });
  final String jid;
  final String avatarUrl;
  final String displayName;
  final void Function(String, String) setAvatar;

  Future<void> pickAndSetAvatar(BuildContext context) async {
    final avatar = await pickAvatar(context, jid, avatarUrl);

    if (avatar != null) {
      setAvatar(avatar.path, avatar.hash);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'self_profile_picture',
          child: Material(
            child: AvatarWrapper(
              radius: 110,
              avatarUrl: avatarUrl,
              altIcon: Icons.person,
              onTapFunction: () => pickAndSetAvatar(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                jid,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 3),
                child: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => showQrCode(context, 'xmpp:$jid'),
                ),
              )
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              left: 64,
              right: 64,
            ),
            child: ProfileOptions(
              options: [
                ProfileOption(
                  icon: Icons.security_outlined,
                  title: t.pages.profile.general.omemo,
                  onTap: () {
                    context.read<OwnDevicesBloc>().add(
                          OwnDevicesRequestedEvent(),
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
