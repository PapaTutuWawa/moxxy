import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
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
      // TODO: Translate
      appBar: AppBar(
        title: Text('Server Information'),
      ),
      body: BlocBuilder<ServerInfoBloc, ServerInfoState>(
        builder: (BuildContext context, ServerInfoState state) {
          if (state.working) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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
