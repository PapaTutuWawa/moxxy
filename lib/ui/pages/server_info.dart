import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/state/server_info.dart';
import 'package:moxxyv2/ui/constants.dart';

const TextStyle _labelStyle = TextStyle(
  fontSize: 18,
);

class _ListItem extends StatelessWidget {
  const _ListItem(this.feature, this.supported);

  /// Whether the feature is supported.
  final bool supported;

  /// The name of the feature.
  final String feature;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        supported ? Icons.check : Icons.close,
        color: supported ? Colors.green : Colors.red,
      ),
      title: Text(
        feature,
        style: _labelStyle,
      ),
    );
  }
}

class ServerInfoPage extends StatelessWidget {
  const ServerInfoPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const ServerInfoPage(),
        settings: const RouteSettings(
          name: serverInfoRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.profile.serverInfo.title),
      ),
      body: BlocBuilder<ServerInfoCubit, ServerInfoState>(
        builder: (BuildContext context, ServerInfoState state) {
          if (state.working) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              children: [
                _ListItem('Stream Management', state.streamManagementSupported),
                _ListItem('HTTP File Upload', state.httpFileUploadSupported),
                _ListItem('User Blocking', state.userBlockingSupported),
                _ListItem('Client State Indication', state.csiSupported),
                _ListItem('Message Carbons', state.carbonsSupported),
              ],
            ),
          );
        },
      ),
    );
  }
}
