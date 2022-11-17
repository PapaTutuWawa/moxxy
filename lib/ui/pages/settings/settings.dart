import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const SettingsPage(),
    settings: const RouteSettings(
      name: settingsRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Settings'),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Conversations'),
            tiles: [
              SettingsTile(
                title: const Text('Chat'),
                leading: const Icon(Icons.chat_bubble),
                onPressed: (context) => Navigator.pushNamed(context, conversationSettingsRoute),
              ),
              SettingsTile(
                title: const Text('Network'),
                leading: const Icon(Icons.network_wifi),
                onPressed: (context) => Navigator.pushNamed(context, networkRoute),
              ),
              SettingsTile(
                title: const Text('Privacy'),
                leading: const Icon(Icons.shield),
                onPressed: (context) => Navigator.pushNamed(context, privacyRoute),
              )
            ],
          ),
          SettingsSection(
            title: const Text('Account'),
            tiles: [
              SettingsTile(
                title: const Text('Blocklist'),
                leading: const Icon(Icons.block),
                onPressed: (context) => Navigator.pushNamed(context, blocklistRoute),
              ),
              SettingsTile(
                title: const Text('Sign out'),
                leading: const Icon(Icons.logout),
                onPressed: (context) => showConfirmationDialog(
                  'Sign Out',
                  'You are about to sign out. Proceed?',
                  context,
                  () async {
                    GetIt.I.get<PreferencesBloc>().add(SignedOutEvent());
                  },
                ),
              )
            ],
          ),
          SettingsSection(
            title: const Text('Miscellaneous'),
            tiles: [
              SettingsTile(
                title: const Text('About'),
                leading: const Icon(Icons.info),
                onPressed: (context) => Navigator.pushNamed(context, aboutRoute),
              ),
              SettingsTile(
                title: const Text('Open-Source licenses'),
                leading: const Icon(Icons.description),
                onPressed: (context) => Navigator.pushNamed(context, licensesRoute),
              )
            ],
          ),
          // TODO(Unknown): Maybe also have a switch somewhere
          ...kDebugMode ? [
              SettingsSection(
                title: const Text('Debugging'),
                tiles: [
                  SettingsTile(
                    title: const Text('Debugging options'),
                    leading: const Icon(Icons.info),
                    onPressed: (context) => Navigator.pushNamed(context, debuggingRoute),
                  )
                ],
              )
            ] : [] 
        ],
      ),
    );
  }
}
