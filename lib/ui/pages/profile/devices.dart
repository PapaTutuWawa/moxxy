import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/widgets.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum DevicesOptions {
  recreateSessions,
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const DevicesPage(),
    settings: const RouteSettings(
      name: devicesRoute,
    ),
  );
  
  Widget _buildBody(BuildContext context, DevicesState state) {
    if (state.working) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final hasVerifiedDevices = state.devices.any((item) => item.verified);
    return ListView.builder(
      itemCount: state.devices.length,
      itemBuilder: (context, index) {
        final item = state.devices[index];
        final fingerprint = item.fingerprint;

        return FingerprintListItem(
          fingerprint,
          item.enabled,
          item.verified,
          hasVerifiedDevices,
          onVerifiedPressed: () {
            if (item.verified) return;

            // TODO(PapaTutuWawa): Implement
            showNotImplementedDialog('verification feature', context);
          },
          onEnableValueChanged: (value) {
            context.read<DevicesBloc>().add(
              DeviceEnabledSetEvent(
                item.deviceId,
                value,
              ),
            );
          },
        );
      },
    );
  }

  void _recreateSessions(BuildContext context) {
    showConfirmationDialog(
      'Recreate sessions?',
      "This will recreate the cryptographic sessions with the contact. Use only if this device throws decryption errors or your contact's devices throw decryption errors.",
      context,
      () {
        context.read<DevicesBloc>().add(SessionsRecreatedEvent());
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesBloc, DevicesState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          'Devices',
          extra: [
            const Spacer(),
            PopupMenuButton(
              onSelected: (DevicesOptions result) {
                if (result == DevicesOptions.recreateSessions) {
                  _recreateSessions(context);
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: DevicesOptions.recreateSessions,
                  enabled: state.devices.isNotEmpty,
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
