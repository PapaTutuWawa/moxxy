import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";

class PostRegistrationPage extends StatelessWidget {
  // TODO
  final TextEditingController controller = TextEditingController(text: "Testuser");

  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: 32.0),
              child: Text(
                "This is you!",
                style: TextStyle(
                  fontSize: FONTSIZE_TITLE
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
              child: Row(
                children: [
                  // TODO
                  AvatarWrapper(
                    radius: 35.0,
                    avatarUrl: "https://3.bp.blogspot.com/-tXOVVeovbNA/XI8EEkbKjgI/AAAAAAAAJrs/3lOV4RQx9kIp9jWBmZhSKyng9iNQrDivgCLcBGAs/s2560/hatsune-miku-4k-fx-2048x2048.jpg",
                    alt: Text("Tu"),
                    showEditButton: true,
                    onTapFunction: () {}
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TODO: Show a SnackBar if changed
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: CustomTextField(
                            maxLines: 1,
                            labelText: "Display name",
                            controller: this.controller,
                            isDense: true,
                            cornerRadius: TEXTFIELD_RADIUS_REGULAR
                          )
                        ),
                        // TODO
                        Text("testuser@someprovider.net")
                      ]
                    )
                  )
                ]
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 16.0)),
              child: Text(
                "We have auto-generated a password for you. You should write it down somewhere safe.",
                style: TextStyle(
                  fontSize: FONTSIZE_BODY
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 16.0)),
              child: ExpansionTile(
                title: Text("Show password"),
                children: [
                  ListTile(title: Text("s3cr3t_p4ssw0rd"))
                ]
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
              child: ExpansionTile(
                title: Text("Advanced settings"),
                children: [
                  SwitchListTile(
                    title: Text("Enable link previews"),
                    value: true,
                    // TODO
                    onChanged: (value) {}
                  ),
                  SwitchListTile(
                    title: Text("Use Push Services"),
                    value: true,
                    // TODO
                    onChanged: (value) {}
                  )
                ]
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 16.0)),
              child: Text(
                "You can now be contacted by your XMPP address. If you want to set a display name, just tap the text next to the profile picture.",
                style: TextStyle(
                  fontSize: FONTSIZE_BODY
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: Text("Start chatting"),
                      // TODO
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/conversations", (route) => false)
                    )
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}
