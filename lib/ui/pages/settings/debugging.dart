import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
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
      appBar: BorderlessTopbar.simple(t.pages.settings.debugging.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: Text(t.pages.settings.debugging.generalSection),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.debugging.generalEnableDebugging),
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(debugEnabled: value),
                    ),
                  ),
                  initialValue: state.debugEnabled,
                ),
                SettingsTile(
                  title: Text(t.pages.settings.debugging.generalEncryptionPassword),
                  description: Text(t.pages.settings.debugging.generalEncryptionPasswordSubtext),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(t.pages.settings.debugging.generalEncryptionPassword),
                        content: TextField(
                          minLines: 1,
                          obscureText: true,
                          controller: _passphraseController,
                        ),
                        actions: [
                          TextButton(
                            child: Text(t.global.dialogAccept),
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
                  title: Text(t.pages.settings.debugging.generalLoggingIp),
                  description: Text(t.pages.settings.debugging.generalLoggingIpSubtext),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(t.pages.settings.debugging.generalLoggingIp),
                        content: TextField(
                          minLines: 1,
                          controller: _ipController,
                        ),
                        actions: [
                          TextButton(
                            child: Text(t.global.dialogAccept),
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
                  title: Text(t.pages.settings.debugging.generalLoggingPort),
                  description: Text(t.pages.settings.debugging.generalLoggingPortSubtext),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(t.pages.settings.debugging.generalLoggingPort),
                        content: TextField(
                          minLines: 1,
                          controller: _portController,
                          keyboardType: TextInputType.number,
                        ),
                        actions: [
                          TextButton(
                            child: Text(t.global.dialogAccept),
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
