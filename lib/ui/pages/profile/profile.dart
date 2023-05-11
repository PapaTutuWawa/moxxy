import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/shared_media_controller.dart';
import 'package:moxxyv2/ui/pages/profile/conversationheader.dart';
import 'package:moxxyv2/ui/pages/profile/selfheader.dart';
import 'package:moxxyv2/ui/pages/profile/shared_media_view.dart';

class ProfileArguments {
  ProfileArguments(this.isSelfProfile, this.jid);

  bool isSelfProfile;

  /// The JID of the conversation entity.
  String jid;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage(this.arguments, {super.key});

  /// The arguments passed to the page
  final ProfileArguments arguments;
  
  static MaterialPageRoute<dynamic> getRoute(ProfileArguments arguments) => MaterialPageRoute<dynamic>(
        builder: (_) => ProfilePage(arguments),
        settings: const RouteSettings(
          name: profileRoute,
        ),
      );

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late final PageController _pageController;

  int _pageIndex = 0;

  late final BidirectionalSharedMediaController _mediaController;
  
  @override
  void initState() {
    super.initState();

    _pageController = PageController()
      ..addListener(_onPageControllerUpdate);
    _mediaController = BidirectionalSharedMediaController(
      widget.arguments.jid,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  void _onPageControllerUpdate() {
    if (_pageController.hasClients) {
      final page = _pageController.page!.round();
      if (page != _pageIndex) {
        setState(() {
          _pageIndex = page;
        });
      } else if (_pageController.page! >= 0.5 && !_mediaController.hasFetchedOnce) {
        _mediaController.fetchOlderData();
      }
    }
  }

  Widget _buildHeader(BuildContext context, ProfileState state) {
    if (widget.arguments.isSelfProfile) {
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
        bottomNavigationBar: !widget.arguments.isSelfProfile
          ? BottomNavigationBar(
              currentIndex: _pageIndex,
              onTap: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutQuint,
                );
                setState(() {
                  _pageIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.perm_media),
                  label: 'Media',
                ),
              ],
            )
            : null,
        body: PageView(
          controller: _pageController,
          physics: widget.arguments.isSelfProfile
            ? const NeverScrollableScrollPhysics()
            : null,
          children: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) => Stack(
                alignment: Alignment.center,
                children: [
                  ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildHeader(context, state),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                      context.read<NavigationBloc>().add(PoppedRouteEvent()),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Visibility(
                      visible: widget.arguments.isSelfProfile,
                      child: IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          context
                          .read<ServerInfoBloc>()
                          .add(ServerInfoPageRequested());
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SharedMediaView(
              _mediaController,
              key: const PageStorageKey('shared_media_view'),
            ),
          ],
        ),  
      ),
    );
  }
}
