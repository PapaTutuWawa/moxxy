import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
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
      appBar: BorderlessTopbar.simple(t.pages.settings.settings.title),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(t.pages.settings.settings.conversationsSection),
            tiles: [
              SettingsTile(
                title: Text(t.pages.settings.conversation.title),
                leading: const Icon(Icons.chat_bubble),
                onPressed: (context) => Navigator.pushNamed(context, conversationSettingsRoute),
              ),
              SettingsTile(
                title: Text(t.pages.settings.network.title),
                leading: const Icon(Icons.network_wifi),
                onPressed: (context) => Navigator.pushNamed(context, networkRoute),
              ),
              SettingsTile(
                title: Text(t.pages.settings.privacy.title),
                leading: const Icon(Icons.shield),
                onPressed: (context) => Navigator.pushNamed(context, privacyRoute),
              )
            ],
          ),
          SettingsSection(
            title: Text(t.pages.settings.settings.accountSection),
            tiles: [
              SettingsTile(
                title: Text(t.pages.blocklist.title),
                leading: const Icon(Icons.block),
                onPressed: (context) => Navigator.pushNamed(context, blocklistRoute),
              ),
              SettingsTile(
                title: Text(t.pages.settings.settings.signOut),
                leading: const Icon(Icons.logout),
                onPressed: (context) async {
                  final result = await showConfirmationDialog(
                    t.pages.settings.settings.signOutConfirmTitle,
                    t.pages.settings.settings.signOutConfirmBody,
                    context,
                  );

                  if (result) {
                    GetIt.I.get<PreferencesBloc>().add(SignedOutEvent());
                  }
                },
              )
            ],
          ),
          SettingsSection(
            title: Text(t.pages.settings.settings.miscellaneousSection),
            tiles: [
              SettingsTile(
                title: Text(t.pages.settings.appearance.title),
                leading: const Icon(Icons.brush),
                onPressed: (context) => Navigator.pushNamed(context, appearanceRoute),
              ),
              SettingsTile(
                title: Text(t.pages.settings.about.title),
                leading: const Icon(Icons.info),
                onPressed: (context) => Navigator.pushNamed(context, aboutRoute),
              ),
              SettingsTile(
                title: Text(t.pages.settings.licenses.title),
                leading: const Icon(Icons.description),
                onPressed: (context) => Navigator.pushNamed(context, licensesRoute),
              )
            ],
          ),
          // TODO(Unknown): Maybe also have a switch somewhere
          ...kDebugMode ? [
              SettingsSection(
                title: Text(t.pages.settings.settings.debuggingSection),
                tiles: [
                  SettingsTile(
                    title: Text(t.pages.settings.debugging.title),
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
