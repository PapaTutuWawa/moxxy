import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/debug.dart' as debug;
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/state/preferences.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';

class DebuggingPage extends StatelessWidget {
  DebuggingPage({super.key})
      : _ipController = TextEditingController(),
        _passphraseController = TextEditingController(),
        _portController = TextEditingController();
  final TextEditingController _ipController;
  final TextEditingController _portController;
  final TextEditingController _passphraseController;

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => DebuggingPage(),
        settings: const RouteSettings(
          name: debuggingRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.debugging.title),
      ),
      body: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            SectionTitle(t.pages.settings.debugging.generalSection),
            SettingsRow(
              title: t.pages.settings.debugging.generalEnableDebugging,
              suffix: Switch(
                value: state.debugEnabled,
                onChanged: (value) {
                  context.read<PreferencesCubit>().change(
                        state.copyWith(debugEnabled: value),
                      );
                },
              ),
            ),
            SettingsRow(
              title: t.pages.settings.debugging.generalEncryptionPassword,
              description:
                  t.pages.settings.debugging.generalEncryptionPasswordSubtext,
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(
                      t.pages.settings.debugging.generalEncryptionPassword,
                    ),
                    content: TextField(
                      minLines: 1,
                      obscureText: true,
                      controller: _passphraseController,
                    ),
                    actions: [
                      TextButton(
                        child: Text(t.global.dialogAccept),
                        onPressed: () {
                          context.read<PreferencesCubit>().change(
                                state.copyWith(
                                  debugPassphrase: _passphraseController.text,
                                ),
                              );
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            SettingsRow(
              title: t.pages.settings.debugging.generalLoggingIp,
              description: t.pages.settings.debugging.generalLoggingIpSubtext,
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(t.pages.settings.debugging.generalLoggingIp),
                    content: TextField(
                      minLines: 1,
                      obscureText: true,
                      controller: _ipController,
                    ),
                    actions: [
                      TextButton(
                        child: Text(t.global.dialogAccept),
                        onPressed: () {
                          context.read<PreferencesCubit>().change(
                                state.copyWith(debugIp: _ipController.text),
                              );
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            SettingsRow(
              title: t.pages.settings.debugging.generalLoggingPort,
              description: t.pages.settings.debugging.generalLoggingPortSubtext,
              onTap: () {
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
                          context.read<PreferencesCubit>().change(
                                state.copyWith(
                                  debugPort: int.parse(_portController.text),
                                ),
                              );
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Hide the testing commands outside of debug mode
            ...kDebugMode
                ? [
                    const SectionTitle('Testing'),
                    SettingsRow(
                      title: 'Reset stream management state',
                      onTap: () {
                        getForegroundService().send(
                          DebugCommand(
                            id: debug.DebugCommand.clearStreamResumption.id,
                          ),
                          awaitable: false,
                        );
                      },
                    ),
                    SettingsRow(
                      title: 'Request roster',
                      onTap: () {
                        getForegroundService().send(
                          DebugCommand(
                            id: debug.DebugCommand.requestRoster.id,
                          ),
                          awaitable: false,
                        );
                      },
                    ),
                    SettingsRow(
                      title: 'Log available media files',
                      onTap: () {
                        getForegroundService().send(
                          DebugCommand(
                            id: debug.DebugCommand.logAvailableMediaFiles.id,
                          ),
                          awaitable: false,
                        );
                      },
                    ),
                    SettingsRow(
                      title: 'Reset showDebugMenu state',
                      onTap: () {
                        context.read<PreferencesCubit>().change(
                              state.copyWith(
                                showDebugMenu: false,
                              ),
                            );
                      },
                    ),
                  ]
                : [],
          ],
        ),
      ),
    );
  }
}
