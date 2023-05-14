import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/pages/profile/conversationheader.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/pages/profile/selfheader.dart';

class ProfileView extends StatelessWidget {
  const ProfileView(this.arguments, {super.key});

  final ProfileArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: arguments.isSelfProfile
                    ? SelfProfileHeader(arguments)
                    : const ConversationProfileHeader(),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Visibility(
              visible: arguments.isSelfProfile,
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  context.read<ServerInfoBloc>().add(ServerInfoPageRequested());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
