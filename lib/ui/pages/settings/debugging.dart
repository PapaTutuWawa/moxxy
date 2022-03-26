import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/bloc/preferences_bloc.dart";
import "package:moxxyv2/shared/preferences.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class DebuggingPage extends StatelessWidget {
  final TextEditingController _ipController;
  final TextEditingController _portController;
  final TextEditingController _passphraseController;

  DebuggingPage({ Key? key }) : _ipController = TextEditingController(), _passphraseController = TextEditingController(), _portController = TextEditingController(), super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Debugging"),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "General",
              tiles: [
                SettingsTile.switchTile(
                  title: "Enable debugging",
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(debugEnabled: value)
                    )
                  ),
                  switchValue: state.debugEnabled
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
                              context.read<PreferencesBloc>().add(
                                PreferencesChangedEvent(
                                  state.copyWith(debugPassphrase: _passphraseController.text)
                                )
                              );
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
                              context.read<PreferencesBloc>().add(
                                PreferencesChangedEvent(
                                  state.copyWith(debugIp: _ipController.text)
                                )
                              );
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
                              context.read<PreferencesBloc>().add(
                                PreferencesChangedEvent(
                                  state.copyWith(debugPort: int.parse(_portController.text))
                                )
                              );
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
