import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class DebuggingPage extends StatelessWidget {

  DebuggingPage({ super.key })
    : _ipController = TextEditingController(),
      _passphraseController = TextEditingController(),
      _portController = TextEditingController();
  final TextEditingController _ipController;
  final TextEditingController _portController;
  final TextEditingController _passphraseController;

  static MaterialPageRoute <dynamic>get route => MaterialPageRoute<dynamic>(
    builder: (_) => DebuggingPage(),
    settings: const RouteSettings(
      name: debuggingRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Debugging'),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: const Text('General'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Enable debugging'),
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(debugEnabled: value),
                    ),
                  ),
                  initialValue: state.debugEnabled,
                ),
                SettingsTile(
                  title: const Text('Encryption password'),
                  description: const Text('The logs may contain sensitive information so pick a strong passphrase'),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Debug Passphrase'),
                        content: TextField(
                          minLines: 1,
                          obscureText: true,
                          controller: _passphraseController,
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Okay'),
                            onPressed: () {
                              context.read<PreferencesBloc>().add(
                                PreferencesChangedEvent(
                                  state.copyWith(debugPassphrase: _passphraseController.text),
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: const Text('Logging IP'),
                  description: const Text('The IP the logs should be sent to'),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Logging IP'),
                        content: TextField(
                          minLines: 1,
                          controller: _ipController,
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Okay'),
                            onPressed: () {
                              context.read<PreferencesBloc>().add(
                                PreferencesChangedEvent(
                                  state.copyWith(debugIp: _ipController.text),
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: const Text('Logging Port'),
                  description: const Text('The Port the logs should be sent to'),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Logging Port'),
                        content: TextField(
                          minLines: 1,
                          controller: _portController,
                          keyboardType: TextInputType.number,
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Okay'),
                            onPressed: () {
                              context.read<PreferencesBloc>().add(
                                PreferencesChangedEvent(
                                  state.copyWith(debugPort: int.parse(_portController.text)),
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      ),
                    );
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
