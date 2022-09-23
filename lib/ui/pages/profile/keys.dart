import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/keys_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
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
  
  Widget _buildBody(KeysState state) {
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
        var fingerprint = item.fingerprint;

        final parts = List<String>.empty(growable: true);
        for (var i = 0; i < 8; i++) {
          final part = fingerprint.substring(0, 8);
          fingerprint = fingerprint.substring(8);
          parts.add(part);
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(textfieldRadiusRegular),
            ),
            color: !item.verified && hasVerifiedKeys ? Colors.red : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    children: parts
                    .map((part_) => Text(
                      part_,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 18,
                      ),
                    ),).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Switch(
                        value: item.enabled,
                        onChanged: (value) {
                          context.read<KeysBloc>().add(
                            KeyEnabledSetEvent(
                              item.deviceId,
                              value,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          item.verified ?
                            Icons.verified_user :
                            Icons.qr_code_scanner,
                        ),
                        onPressed: () {
                          if (item.verified) return;

                          // TODO(PapaTutuWawa): Implement
                          showNotImplementedDialog('verification feature', context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeysBloc, KeysState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          'Keys',
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
                const PopupMenuItem(
                  value: KeysOptions.recreateSessions,
                  enabled: state.keys.isNotEmpty,
                  child: Text('Rebuild sessions'),
                )
              ],
            ),
          ],
        ),
        body: _buildBody(state),
      ),
    );
  }
}
