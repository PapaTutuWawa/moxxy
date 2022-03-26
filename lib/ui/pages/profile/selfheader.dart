import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";

import "package:flutter/material.dart";
import "package:qr_flutter/qr_flutter.dart";

class SelfProfileHeader extends StatelessWidget {
  final String jid;
  final String avatarUrl;
  final String displayName;
  
  const SelfProfileHeader(
    this.jid,
    this.avatarUrl,
    this.displayName,
    {
      Key? key
    }
  ) : super(key: key);

  Future<void> _showJidQRCode(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(jid),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: QrImage(
                // TODO: Check if the URI is correct
                data: "xmpp:" + jid,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
                embeddedImage: const AssetImage("assets/images/logo.png"),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: const Size(50, 50)
                )
              )
            )
          ) 
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: avatarUrl,
          altIcon: Icons.person,
          showEditButton: false,
          // TODO
          //onTapFunction: () => pickAndSetAvatar(context, viewModel.setAvatarUrl, viewModel.avatarUrl)
          onTapFunction: () {}
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20
                )
              )
            ]
          )
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                jid,
                style: const TextStyle(
                  fontSize: 15
                )
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 3.0),
                child: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showJidQRCode(context)
                )
              )
            ]
          )
        )
      ]
    );
  }
}
