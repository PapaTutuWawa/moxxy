import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/sharedmedia.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/models/conversation.dart';

// TODO: Move to separate file
class ProfilePageArguments {
  final Conversation? conversation;
  final bool isSelfProfile;

  ProfilePageArguments({ this.conversation, required this.isSelfProfile }) {
    assert(this.isSelfProfile ? true : this.conversation != null);
  }
}

class SelfProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: "https://3.bp.blogspot.com/-tXOVVeovbNA/XI8EEkbKjgI/AAAAAAAAJrs/3lOV4RQx9kIp9jWBmZhSKyng9iNQrDivgCLcBGAs/s2560/hatsune-miku-4k-fx-2048x2048.jpg",
          altText: "?",
          showEditButton: true,
          onTapFunction: () {}
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            // TODO
            "Testuser",
            style: TextStyle(
              fontSize: 30
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 3.0),
          child: Text(
            // TODO
            "testuser@someserver.net",
            style: TextStyle(
              fontSize: 15
            )
          )
        )
      ]
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final Conversation conversation;

  ProfileHeader({ required this.conversation });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: this.conversation.avatarUrl,
          altText: this.conversation.title[0]
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            this.conversation.title,
            style: TextStyle(
              fontSize: 30
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 3.0),
          child: Text(
            this.conversation.jid,
            style: TextStyle(
              fontSize: 15
            )
          )
        )
      ]
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as ProfilePageArguments;
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Column(
                children: [
                  args.isSelfProfile ? SelfProfileHeader() : ProfileHeader(conversation: args.conversation!),
                  Visibility(
                    visible: !args.isSelfProfile && args.conversation!.sharedMediaPaths.length > 0,
                    child: args.isSelfProfile ? SizedBox() : SharedMediaDisplay(
                      sharedMediaPaths: args.conversation!.sharedMediaPaths
                    )
                  ) 
                ]
              ),
              top: 8.0,
              bottom: null,
              left: null,
              right: null
            ),
            Positioned(
              top: 8.0,
              left: 8.0,
              child: BackButton()
            )
          ]
        )
      )
    );
  }
}
