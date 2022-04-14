import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

import "package:flutter/material.dart";
import "package:qr_flutter/qr_flutter.dart";

class SelfProfileHeader extends StatelessWidget {
  final String jid;
  final String avatarUrl;
  final String displayName;
  final List<String> serverFeatures;
  final List<String> streamFeatures;
  final void Function(String, String) setAvatar;
  
  const SelfProfileHeader(
    this.jid,
    this.avatarUrl,
    this.displayName,
    this.serverFeatures,
    this.streamFeatures,
    this.setAvatar,
    {
      Key? key
    }
  ) : super(key: key);

  Widget _buildServerCheck(String title, String namespace) {
    return IntrinsicWidth(
      child: Row(
        children: [
          Text(title),
          Checkbox(
            value: serverFeatures.contains(namespace),
            onChanged: (_) {}
          )
        ]
      )
    );
  }

  Widget _buildStreamCheck(String title, String namespace) {
    return IntrinsicWidth(
      child: Row(
        children: [
          Text(title),
          Checkbox(
            value: streamFeatures.contains(namespace),
            onChanged: (_) {}
          )
        ]
      )
    );
  }
  
  Future<void> _showJidQRCode(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: QrImage(
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

  Future<void> pickAndSetAvatar(BuildContext context) async {
    final avatar = await pickAvatar(context, jid, avatarUrl);

    if (avatar != null) {
      setAvatar(avatar.path, avatar.hash);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: "self_profile_picture",
          child: Material(
            child: AvatarWrapper(
              radius: 110.0,
              avatarUrl: avatarUrl,
              altIcon: Icons.person,
              showEditButton: false,
              onTapFunction: () => pickAndSetAvatar(context)
            )
          )
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
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ExpansionTile(
            title: const Text("Server information"),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStreamCheck("StreamManagement", smXmlns),
                  _buildServerCheck("Message Carbons", carbonsXmlns),
                  _buildServerCheck("Blocklist", blockingXmlns),
                  _buildServerCheck("HTTP File Upload", httpFileUploadXmlns),
                ]
              )
            ]
          )
        ) 
      ]
    );
  }
}
