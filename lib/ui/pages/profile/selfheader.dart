import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Builds the widget that will be put into the modal BottomSheet where the user can see
/// what features their server supports that are "crucial" to Moxxy.
Widget buildServerInformationModal() {
  return BlocBuilder<ProfileBloc, ProfileState>(
    buildWhen: (prev, next) {
      return prev.streamManagementSupported != next.streamManagementSupported ||
             prev.httpFileUploadSupported != next.httpFileUploadSupported ||
             prev.userBlockingSupported != next.userBlockingSupported ||
             prev.csiSupported != next.csiSupported;
    },
    builder: (context, state) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Server Information',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),

        Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const Text('Stream Management'),
                Checkbox(
                  value: state.streamManagementSupported,
                  onChanged: (_) {},
                ),
              ],
            ),
            TableRow(
              children: [
                const Text('HTTP File Upload'),
                Checkbox(
                  value: state.httpFileUploadSupported,
                  onChanged: (_) {},
                ),
              ],
            ),
            TableRow(
              children: [
                const Text('User Blocking'),
                Checkbox(
                  value: state.userBlockingSupported,
                  onChanged: (_) {},
                ),
              ],
            ),
            TableRow(
              children: [
                const Text('Client State Indication'),
                Checkbox(
                  value: state.csiSupported,
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class SelfProfileHeader extends StatelessWidget {
  
  const SelfProfileHeader(
    this.jid,
    this.avatarUrl,
    this.displayName,
    this.streamManagementSupported,
    this.setAvatar,
    {
      Key? key,
    }
  ) : super(key: key);
  final String jid;
  final String avatarUrl;
  final String displayName;
  final bool streamManagementSupported;
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
      ],
    );
  }
}
