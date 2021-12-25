import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";

class PostRegistrationPage extends StatelessWidget {
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
                  fontSize: 40
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
              child: InkWell(
                child: Row(
                  children: [
                    // TODO
                    // TODO: Add an icon
                    CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage("https://3.bp.blogspot.com/-tXOVVeovbNA/XI8EEkbKjgI/AAAAAAAAJrs/3lOV4RQx9kIp9jWBmZhSKyng9iNQrDivgCLcBGAs/s2560/hatsune-miku-4k-fx-2048x2048.jpg"),
                      radius: 35.0
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO: Maybe have a TextField here
                          Text(
                            "Testuser",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25
                            )
                          ),
                          Text("testuser@someprovider.net")
                        ]
                      )
                    )
                  ]
                ),
                // TODO
                onTap: () {}
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 64.0).add(EdgeInsets.only(top: 16.0)),
              child: Text(
                "We have auto-generated a password for you. You should write it down somewhere sage.",
                style: TextStyle(
                  fontSize: 15
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 64.0).add(EdgeInsets.only(top: 16.0)),
              child: ExpansionTile(
                title: Text("Show password"),
                children: [
                  ListTile(title: Text("s3cr3t_p4ssw0rd"))
                ]
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 64.0),
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
              padding: EdgeInsets.symmetric(horizontal: 64.0).add(EdgeInsets.only(top: 16.0)),
              child: Text("You can now be contacted by your XMPP address. If you want to set a profile picture, just tap your name.")
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 64.0),
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
