import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/own_devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/profile/options.dart';

class SelfProfileHeader extends StatelessWidget {
  const SelfProfileHeader(this.arguments, {super.key});

  final ProfileArguments arguments;

  Future<void> pickAndSetAvatar(BuildContext context, String avatarUrl) async {
    final result = await pickAvatar(context, arguments.jid, avatarUrl);
    if (result != null) {
      final (avatarPath, avatarHash) = result;

      // ignore: use_build_context_synchronously
      context.read<ProfileBloc>().add(
            AvatarSetEvent(avatarPath, avatarHash, true),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return Column(
          children: [
            Hero(
              tag: 'self_profile_picture',
              child: Material(
                child: CachingXMPPAvatar.self(
                  radius: 110,
                  onTap: () => pickAndSetAvatar(context, state.avatarUrl),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    arguments.jid,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 3),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () =>
                          showQrCode(context, 'xmpp:${arguments.jid}'),
                    ),
                  ),
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
      },
    );
  }
}
