import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/own_devices.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/widgets.dart';

enum OwnDevicesOptions {
  recreateSessions,
  recreateDevice,
}

class OwnDevicesPage extends StatelessWidget {
  const OwnDevicesPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (context) => const OwnDevicesPage(),
        settings: const RouteSettings(
          name: ownDevicesRoute,
        ),
      );

  Future<void> _showDeviceQRCode(
    BuildContext context,
    int deviceId,
    String fingerprint,
  ) async {
    final jid = GetIt.I.get<AccountCubit>().state.account.jid;
    showQrCode(
      context,
      'xmpp:$jid?omemo2-sid-$deviceId=$fingerprint',
      embedLogo: false,
    );
  }

  Widget _buildBody(BuildContext context, OwnDevicesState state) {
    if (state.working) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final hasVerifiedDevices = state.keys.any((item) => item.verified);
    return ListView.builder(
      itemCount: state.keys.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                  ),
                  child: Text(
                    t.pages.profile.owndevices.thisDevice,
                    style: const TextStyle(
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
                  _showDeviceQRCode(
                    context,
                    state.deviceId,
                    state.deviceFingerprint,
                  );
                },
              ),
              if (state.keys.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 32,
                      left: 16,
                    ),
                    child: Text(
                      t.pages.profile.owndevices.otherDevices,
                      style: const TextStyle(
                        fontSize: fontsizeSubtitle,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        final item = state.keys[index - 1];
        final fingerprint = item.fingerprint;

        return FingerprintListItem(
          fingerprint,
          item.enabled,
          item.verified,
          hasVerifiedDevices,
          onVerifiedPressed: () async {
            if (item.verified) return;

            final uri = await scanXmppUriQrCode(context);
            if (uri == null) return;

            // ignore: use_build_context_synchronously
            await context.read<OwnDevicesCubit>().verifyDevice(
                  uri,
                  item.deviceId,
                );
          },
          onEnableValueChanged: (value) {
            context.read<OwnDevicesCubit>().setDeviceEnabled(
                  item.deviceId,
                  value,
                );
          },
          onDeletePressed: () async {
            final result = await showConfirmationDialog(
              t.pages.profile.owndevices.deleteDeviceConfirmTitle,
              t.pages.profile.owndevices.deleteDeviceConfirmBody,
              context,
            );

            if (result) {
              // ignore: use_build_context_synchronously
              await context.read<OwnDevicesCubit>().removeDevice(item.deviceId);
            }
          },
        );
      },
    );
  }

  Future<void> _recreateSessions(BuildContext context) async {
    final result = await showConfirmationDialog(
      t.pages.profile.owndevices.recreateOwnSessionsConfirmTitle,
      t.pages.profile.owndevices.recreateOwnSessionsConfirmBody,
      context,
    );

    if (result) {
      // ignore: use_build_context_synchronously
      await context.read<OwnDevicesCubit>().recreateSessions();
    }
  }

  Future<void> _recreateDevice(BuildContext context) async {
    final result = await showConfirmationDialog(
      t.pages.profile.owndevices.recreateOwnDeviceConfirmTitle,
      t.pages.profile.owndevices.recreateOwnDeviceConfirmBody,
      context,
    );

    if (result) {
      // ignore: use_build_context_synchronously
      await context.read<OwnDevicesCubit>().regenerateDevice();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OwnDevicesCubit, OwnDevicesState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(t.pages.profile.owndevices.title),
          actions: [
            PopupMenuButton(
              onSelected: (OwnDevicesOptions result) {
                switch (result) {
                  case OwnDevicesOptions.recreateSessions:
                    _recreateSessions(context);
                  case OwnDevicesOptions.recreateDevice:
                    _recreateDevice(context);
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: OwnDevicesOptions.recreateSessions,
                  enabled: state.keys.isNotEmpty,
                  child: Text(t.pages.profile.owndevices.recreateOwnSessions),
                ),
                PopupMenuItem(
                  value: OwnDevicesOptions.recreateDevice,
                  child: Text(t.pages.profile.owndevices.recreateOwnDevice),
                ),
              ],
            ),
          ],
        ),
        body: _buildBody(context, state),
      ),
    );
  }
}
