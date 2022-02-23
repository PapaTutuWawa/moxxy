import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/debug/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_redux/flutter_redux.dart";

class _DebuggingPageViewModel {
  final bool enabled;
  final void Function(bool) setEnabled;
  final void Function(String) setIp;
  final void Function(int) setPort;
  final void Function(String) setPassphrase;

  _DebuggingPageViewModel({ required this.enabled, required this.setEnabled, required this.setIp, required this.setPort, required this.setPassphrase });
}

class DebuggingPage extends StatelessWidget {
  final TextEditingController _ipController;
  final TextEditingController _portController;
  final TextEditingController _passphraseController;

  DebuggingPage({ Key? key }) : _ipController = TextEditingController(), _passphraseController = TextEditingController(), _portController = TextEditingController(), super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Debugging"),
      body: StoreConnector<MoxxyState, _DebuggingPageViewModel>(
        converter: (store) => _DebuggingPageViewModel(
          enabled: store.state.debugState.enabled,
          setEnabled: (enabled) => store.dispatch(DebugSetEnabledAction(enabled, false)),
          setPort: (port) => store.dispatch(DebugSetPortAction(port)),
          setIp: (ip) => store.dispatch(DebugSetIpAction(ip)),
          setPassphrase: (passphrase) => store.dispatch(DebugSetPassphraseAction(passphrase))
        ),
        builder: (context, viewModel) => SettingsList(
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "General",
              tiles: [
                SettingsTile.switchTile(
                  title: "Enable debugging",
                  onToggle: (value) => viewModel.setEnabled(value),
                  switchValue: viewModel.enabled
                ),
                SettingsTile(
                  title: "Encryption password",
                  subtitle: "The logs may contain sensitive information so pick a strong passphrase",
                  subtitleMaxLines: 2,
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text("Debug Passphrase"),
                        content: TextField(
                          maxLines: 1,
                          minLines: 1,
                          obscureText: true,
                          controller: _passphraseController
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Okay"),
                            onPressed: () {
                              viewModel.setPassphrase(_passphraseController.text);
                              Navigator.of(context).pop();
                            }
                          )
                        ]
                      )
                    );
                  }
                ),
                SettingsTile(
                  title: "Logging IP",
                  subtitle: "The IP the logs should be sent to",
                  subtitleMaxLines: 2,
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text("Logging IP"),
                        content: TextField(
                          maxLines: 1,
                          minLines: 1,
                          controller: _ipController
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Okay"),
                            onPressed: () {
                              viewModel.setIp(_ipController.text);
                              Navigator.of(context).pop();
                            }
                          )
                        ]
                      )
                    );
                  }
                ),
                SettingsTile(
                  title: "Logging Port",
                  subtitle: "The Port the logs should be sent to",
                  subtitleMaxLines: 2,
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text("Logging Port"),
                        content: TextField(
                          maxLines: 1,
                          minLines: 1,
                          controller: _portController,
                          keyboardType: TextInputType.number
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Okay"),
                            onPressed: () {
                              viewModel.setPort(int.parse(_portController.text));
                              Navigator.of(context).pop();
                            }
                          )
                        ]
                      )
                    );
                  }
                )
              ]
            )
          ]
        )
      )
    );
  }
}
