import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/sharedmedia.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/models/conversation.dart';

// TODO: Move to separate file
class ProfilePageArguments {
  final Conversation conversation;

  ProfilePageArguments({ required this.conversation });
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
                  AvatarWrapper(
                    radius: 110.0,
                    avatarUrl: args.conversation.avatarUrl,
                    altText: args.conversation.title[0],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      args.conversation.title,
                      style: TextStyle(
                        fontSize: 30
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 3.0),
                    child: Text(
                      args.conversation.jid,
                      style: TextStyle(
                        fontSize: 15
                      )
                    )
                  ),
                  Visibility(
                    visible: args.conversation.sharedMediaPaths.length > 0,
                    child: SharedMediaDisplay(
                      sharedMediaPaths: args.conversation.sharedMediaPaths
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
