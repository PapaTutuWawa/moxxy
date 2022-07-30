import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/pages/profile/conversationheader.dart';
import 'package:moxxyv2/ui/pages/profile/selfheader.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/media.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({ Key? key }) : super(key: key);
 
  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(builder: (_) => const ProfilePage());
  
  Widget _buildHeader(BuildContext context, ProfileState state) {
    if (state.isSelfProfile) {
      return SelfProfileHeader(
        state.jid,
        state.avatarUrl,
        state.displayName,
        state.serverFeatures,
        state.streamManagementSupported,
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

                  // TODO(Unknown): Maybe don't show this conditionally but always
                  Visibility(
                    visible: !state.isSelfProfile && state.conversation!.sharedMedia.isNotEmpty,
                    child: state.isSelfProfile ? const SizedBox() : SharedMediaDisplay(
                      state.conversation!.sharedMedia,
                      state.conversation!.jid,
                    ),
                  )
                ],
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => context.read<NavigationBloc>().add(PoppedRouteEvent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
