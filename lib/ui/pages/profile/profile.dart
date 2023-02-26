import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/profile/conversationheader.dart';
import 'package:moxxyv2/ui/pages/profile/selfheader.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/media.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({ super.key });
 
  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const ProfilePage(),
    settings: const RouteSettings(
      name: profileRoute,
    ),
  );
  
  Widget _buildHeader(BuildContext context, ProfileState state) {
    if (state.isSelfProfile) {
      return SelfProfileHeader(
        state.jid,
        state.avatarUrl,
        state.displayName,
        (path, hash) => context.read<ProfileBloc>().add(
          AvatarSetEvent(path, hash),
        ),
      );
    }

    return ConversationProfileHeader(state.conversation!);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) => Stack(
            alignment: Alignment.center,
            children: [
              ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildHeader(context, state),
                  ),

                  if (!state.isSelfProfile && state.conversation!.sharedMedia.isNotEmpty)
                    SharedMediaDisplay(
                      preview: state.conversation!.sharedMedia,
                      jid: state.conversation!.jid,
                      title: state.conversation!.titleWithOptionalContact,
                      sharedMediaAmount: state.conversation!.sharedMediaAmount,
                    ),
                ],
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.read<NavigationBloc>().add(PoppedRouteEvent()),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Visibility(
                  visible: state.isSelfProfile,
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
        ),
      ),
    );
  }
}
