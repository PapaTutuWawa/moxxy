import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/own_keys_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/widgets.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum OwnKeysOptions {
  recreateSessions,
}

class OwnKeysPage extends StatelessWidget {
  const OwnKeysPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const OwnKeysPage(),
    settings: const RouteSettings(
      name: ownKeysRoute,
    ),
  );

  Future<void> _showDeviceQRCode(BuildContext context, int deviceId, String fingerprint) async {
    final jid = GetIt.I.get<UIDataService>().ownJid;
    await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: QrImage(
                data: 'xmpp:$jid?omemo-sid-$deviceId=$fingerprint',
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
  
  Widget _buildBody(BuildContext context, OwnKeysState state) {
    if (state.working) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final hasVerifiedKeys = state.keys.any((item) => item.verified);
    return ListView.builder(
      itemCount: state.keys.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                  ),
                  child: Text(
                    'This device',
                    style: TextStyle(
                      fontSize: fontsizeSubtitle,
                    ),
                  ),
                ),
              ),
              FingerprintListItem(
                state.deviceFingerprint,
                true,
                true,
                true,
                onShowQrCodePressed: () {
                  _showDeviceQRCode(context, state.deviceId, state.deviceFingerprint);
                },
              ),
              ...state.keys.isNotEmpty ?
                [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 32,
                        left: 16,
                      ),
                      child: Text(
                        'Other devices',
                        style: TextStyle(
                          fontSize: fontsizeSubtitle,
                        ),
                      ),
                    ),
                  ),
                ] :
                [],
            ],
          );
        }

        final item = state.keys[index - 1];
        final fingerprint = item.fingerprint;
        
        return FingerprintListItem(
          fingerprint,
          item.enabled,
          item.verified,
          hasVerifiedKeys,
          onVerifiedPressed: !item.hasSessionWith ?
            null :
            () {
              if (item.verified) return;

              // TODO(PapaTutuWawa): Implement
              showNotImplementedDialog('verification feature', context);
            },
          onEnableValueChanged: !item.hasSessionWith ?
            null :
            (value) {
              context.read<OwnKeysBloc>().add(
                OwnKeyEnabledSetEvent(
                  item.deviceId,
                  value,
                ),
              );
            },
          onDeletePressed: () {
            context.read<OwnKeysBloc>().add(OwnDeviceRemovedEvent(item.deviceId));
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OwnKeysBloc, OwnKeysState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          'Own Devices',
          extra: [
            const Spacer(),
            PopupMenuButton(
              onSelected: (OwnKeysOptions result) {
                if (result == OwnKeysOptions.recreateSessions) {
                  context.read<OwnKeysBloc>().add(OwnSessionsRecreatedEvent());
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: OwnKeysOptions.recreateSessions,
                  enabled: state.keys.isNotEmpty,
                  child: const Text('Rebuild sessions'),
                )
              ],
            ),
          ],
        ),
        body: _buildBody(context, state),
      ),
    );
  }
}
