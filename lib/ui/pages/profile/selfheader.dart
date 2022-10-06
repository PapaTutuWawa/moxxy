import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/own_devices_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SelfProfileHeader extends StatelessWidget {
  
  const SelfProfileHeader(
    this.jid,
    this.avatarUrl,
    this.displayName,
    this.setAvatar,
    {
      Key? key,
    }
  ) : super(key: key);
  final String jid;
  final String avatarUrl;
  final String displayName;
  final void Function(String, String) setAvatar;

  Future<void> _showJidQRCode(BuildContext context) async {
    await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: QrImage(
                data: 'xmpp:$jid',
                size: 220,
                backgroundColor: Colors.white,
                embeddedImage: const AssetImage('assets/images/logo.png'),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: const Size(50, 50),
                ),
              ),
            ),
          ) 
        ],
      ),
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
      children: [
        Hero(
          tag: 'self_profile_picture',
          child: Material(
            child: AvatarWrapper(
              radius: 110,
              avatarUrl: avatarUrl,
              altIcon: Icons.person,
              onTapFunction: () => pickAndSetAvatar(context),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                jid,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 3),
                child: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showJidQRCode(context),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                message: 'Devices',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SharedMediaContainer(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColoredBox(
                          color: getTileColor(context),
                          child: const Icon(
                            Icons.security_outlined,
                            size: 32,
                          ),
                        ),
                      ),
                      onTap: () {
                        GetIt.I.get<OwnDevicesBloc>().add(OwnDevicesRequestedEvent());
                      },
                    ),
                    const Text(
                      'Devices',
                      style: TextStyle(
                        fontSize: fontsizeAppbar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
