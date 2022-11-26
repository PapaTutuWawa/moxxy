import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

const TextStyle _labelStyle = TextStyle(
  fontSize: 18,
);

class ServerInfoPage extends StatelessWidget {
  const ServerInfoPage({ super.key });
 
  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const ServerInfoPage(),
    settings: const RouteSettings(
      name: serverInfoRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Server Information'),
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
            child: SingleChildScrollView(
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      const Text('Stream Management', style: _labelStyle),
                      Checkbox(
                        value: state.streamManagementSupported,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('HTTP File Upload', style: _labelStyle),
                      Checkbox(
                        value: state.httpFileUploadSupported,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('User Blocking', style: _labelStyle),
                      Checkbox(
                        value: state.userBlockingSupported,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Client State Indication', style: _labelStyle),
                      Checkbox(
                        value: state.csiSupported,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Message Carbons', style: _labelStyle),
                      Checkbox(
                        value: state.carbonsSupported,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
