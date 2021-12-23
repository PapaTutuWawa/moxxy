import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/sharedimage.dart';
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
                  CircleAvatar(
                    // TODO
                    backgroundImage: NetworkImage(args.conversation.avatarUrl),
                    radius: 110.0
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
                        fontSize: 15)
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 25.0),
                    child: Text(
                      "Shared Media",
                      style: TextStyle(
                        fontSize: 25
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          SharedImage(
                            image: NetworkImage(
                              "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.redd.it%2Fv2ybdgx5cow61.jpg&f=1&nofb=1"
                            )
                          ),
                          SharedImage(
                            image: NetworkImage(
                              "https://ih1.redbubble.net/image.1660387906.9194/bg,f8f8f8-flat,750x,075,f-pad,750x1000,f8f8f8.jpg"
                            )
                          ),
                          SharedImage(
                            image: NetworkImage(
                              "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fcdn.donmai.us%2Fsample%2Fb6%2Fe6%2Fsample-b6e62e3edc1c6dfe6afdb54614b4a710.jpg&f=1&nofb=1"
                            )
                          ),
                          SharedImage(
                            image: NetworkImage(
                              "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2F64.media.tumblr.com%2Fec84dc5628ca3d8405374b85a51c7328%2Fbb0fc871a5029726-04%2Fs1280x1920%2Ffa6d89e8a2c2f3ce17465d328c2fe0ed6c951f01.jpg&f=1&nofb=1"
                            )
                          ),
                        ]
                      )
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
