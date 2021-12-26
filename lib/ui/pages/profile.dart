import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/sharedmedia.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/constants.dart';
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
  // This is to keep the snackbar only on this page. This also removes it once
  // we navigate away from this page.
  final GlobalKey<ScaffoldState> scaffoldKey;
  // TODO
  TextEditingController controller = TextEditingController(text: "Testuser");
  bool _showingSnackBar = false;

  SelfProfileHeader({ required this.scaffoldKey });
  
  void _applyDisplayNameChange() {
    // TODO
    // TODO: Maybe show a LinearProgressIndicator
    this._showingSnackBar = false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: "https://3.bp.blogspot.com/-tXOVVeovbNA/XI8EEkbKjgI/AAAAAAAAJrs/3lOV4RQx9kIp9jWBmZhSKyng9iNQrDivgCLcBGAs/s2560/hatsune-miku-4k-fx-2048x2048.jpg",
          alt: Text("?"),
          showEditButton: false,
          onTapFunction: () {}
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 220
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: 1,
                color: BUBBLE_COLOR_SENT
              )
            ),
            child: TextField(
              maxLines: 1,
              controller: this.controller,
              onChanged: (value) {
                if (!this._showingSnackBar) {
                  this._showingSnackBar = true;

                  this.scaffoldKey.currentState!.showSnackBar(SnackBar(
                      // TODO: The colors are kinda bad
                      // TODO: This feels like one big hack
                      duration: Duration(days: 1),
                      backgroundColor: PRIMARY_COLOR,
                      content: Text(
                        "Display name not applied",
                        style: TextStyle(
                          color: Colors.white
                        )
                      ),
                      action: SnackBarAction(
                        label: "Apply",
                        onPressed: this._applyDisplayNameChange,
                        textColor: Colors.blue
                      )
                  ));
                }
              },
              decoration: InputDecoration(
                labelText: "Display name",
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(5.0),
                isDense: true
              )
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
          alt: Text(this.conversation.title[0])
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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as ProfilePageArguments;
    
    return Scaffold(
      key: this.scaffoldKey,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Column(
                children: [
                  args.isSelfProfile ? SelfProfileHeader(scaffoldKey: this.scaffoldKey) : ProfileHeader(conversation: args.conversation!),
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
