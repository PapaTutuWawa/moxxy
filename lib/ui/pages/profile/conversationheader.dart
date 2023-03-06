import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/contact_helper.dart';
import 'package:moxxyv2/ui/widgets/profile/options.dart';
//import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConversationProfileHeader extends StatelessWidget {
  const ConversationProfileHeader(this.conversation, {super.key});
  final Conversation conversation;

  Future<void> _showAvatarFullsize(BuildContext context, String path) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return IgnorePointer(
          child: Image.file(File(path)),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return RebuildOnContactIntegrationChange(
      builder: () {
        final path = conversation.avatarPathWithOptionalContact;
        final avatar = AvatarWrapper(
          radius: 110,
          avatarUrl: path,
          altText: conversation.titleWithOptionalContact,
        );

        if (path != null && path.isNotEmpty) {
          return InkWell(
            onTap: () => _showAvatarFullsize(context, path),
            child: avatar,
          );
        }

        return avatar;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'conversation_profile_picture',
          child: Material(
            child: _buildAvatar(
              context,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: RebuildOnContactIntegrationChange(
            builder: () => Text(
              conversation.titleWithOptionalContact,
              style: const TextStyle(
                fontSize: 30,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            conversation.jid,
            style: const TextStyle(
              fontSize: 15,
            ),
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
                    context.read<DevicesBloc>().add(
                          DevicesRequestedEvent(conversation.jid),
                        );
                  },
                ),
                ProfileOption(
                  icon: conversation.muted
                      ? Icons.notifications_off
                      : Icons.notifications,
                  title: t.pages.profile.conversation.notifications,
                  description: conversation.muted
                      ? t.pages.profile.conversation.notificationsMuted
                      : t.pages.profile.conversation.notificationsEnabled,
                  onTap: () {
                    context.read<ProfileBloc>().add(
                          MuteStateSetEvent(
                            conversation.jid,
                            !conversation.muted,
                          ),
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
