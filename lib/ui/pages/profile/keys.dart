import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/keys_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/profile/widgets.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum KeysOptions {
  recreateSessions,
}

class KeysPage extends StatelessWidget {
  const KeysPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const KeysPage(),
    settings: const RouteSettings(
      name: keysRoute,
    ),
  );
  
  Widget _buildBody(BuildContext context, KeysState state) {
    if (state.working) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final hasVerifiedKeys = state.keys.any((item) => item.verified);
    return ListView.builder(
      itemCount: state.keys.length,
      itemBuilder: (context, index) {
        final item = state.keys[index];
        final fingerprint = item.fingerprint;

        return FingerprintListItem(
          fingerprint,
          item.enabled,
          item.verified,
          hasVerifiedKeys,
          onVerifiedPressed: () {
            if (item.verified) return;

            // TODO(PapaTutuWawa): Implement
            showNotImplementedDialog('verification feature', context);
          },
          onEnableValueChanged: (value) {
            context.read<KeysBloc>().add(
              KeyEnabledSetEvent(
                item.deviceId,
                value,
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeysBloc, KeysState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          'Devices',
          extra: [
            const Spacer(),
            PopupMenuButton(
              onSelected: (KeysOptions result) {
                if (result == KeysOptions.recreateSessions) {
                  context.read<KeysBloc>().add(SessionsRecreatedEvent());
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: KeysOptions.recreateSessions,
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
