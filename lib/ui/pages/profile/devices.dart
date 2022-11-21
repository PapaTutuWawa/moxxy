import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/widgets.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum DevicesOptions {
  recreateSessions,
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({ super.key });

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

  Future<void> _recreateSessions(BuildContext context) async {
    final result = await showConfirmationDialog(
      t.pages.profile.devices.recreateSessionsConfirmTitle,
      t.pages.profile.devices.recreateSessionsConfirmBody,
      context,
    );

    if (result) {
      // ignore: use_build_context_synchronously
      context.read<DevicesBloc>().add(SessionsRecreatedEvent());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesBloc, DevicesState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          t.pages.profile.devices.title,
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
                  child: Text(t.pages.profile.devices.recreateSessions),
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
