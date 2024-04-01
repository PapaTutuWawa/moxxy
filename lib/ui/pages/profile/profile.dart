import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/shared_media_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/profile_view.dart';
import 'package:moxxyv2/ui/widgets/shared_media_view.dart';

class ProfileArguments {
  ProfileArguments(this.isSelfProfile, this.jid, this.type);

  bool isSelfProfile;

  /// The JID of the conversation entity.
  String jid;

  /// Type of the conversation - chat, groupchat, note.
  ConversationType type;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage(this.arguments, {super.key});

  /// The arguments passed to the page
  final ProfileArguments arguments;

  static MaterialPageRoute<dynamic> getRoute(ProfileArguments arguments) =>
      MaterialPageRoute<dynamic>(
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

    _pageController = PageController()..addListener(_onPageControllerUpdate);
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
      } else if (_pageController.page! >= 0.5 &&
          !_mediaController.hasFetchedOnce) {
        _mediaController.fetchOlderData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
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
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.person),
                        label: t.pages.profile.general.profile,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.perm_media),
                        label: t.pages.profile.general.media,
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
                ProfileView(
                  widget.arguments,
                ),
                SharedMediaView(
                  _mediaController,
                  emptyText: t.pages.sharedMedia.empty.chat,
                  showBackButton: false,
                  key: const PageStorageKey('shared_media_view'),
                  onTap: (fm) => openFile(fm.path!),
                  // TODO(Unknown): Allow deleting singular items
                  //onLongPress: (fm) {},
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: context.read<Navigation>().pop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
