import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/bloc/preferences_bloc.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({ Key? key }) : super(key: key);

  static get route => MaterialPageRoute(builder: (_) => const SettingsPage());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple("Settings"),
      body: SettingsList(
        // TODO: Seems hacky
        darkBackgroundColor: const Color(0xff303030),
        contentPadding: const EdgeInsets.all(16.0),
        sections: [
          SettingsSection(
            title: "Account",
            tiles: [
              SettingsTile(
                title: "Blocklist",
                leading: const Icon(Icons.block),
                onPressed: (context) => Navigator.pushNamed(context, blocklistRoute)
              ),
              SettingsTile(
                title: "Sign out",
                leading: const Icon(Icons.logout),
                onPressed: (context) => showConfirmationDialog(
                  "Sign Out",
                  "You are about to sign out. Proceed?",
                  context,
                  () => GetIt.I.get<PreferencesBloc>().add(SignedOutEvent())
                )
              )
            ]
          ),
          SettingsSection(
            title: "Conversations",
            tiles: [
              SettingsTile(
                title: "Appearance",
                leading: const Icon(Icons.brush),
                onPressed: (context) => Navigator.pushNamed(context, appearanceRoute)
              ),
              SettingsTile(
                title: "Network",
                leading: const Icon(Icons.network_wifi),
                onPressed: (context) => Navigator.pushNamed(context, networkRoute)
              ),
              SettingsTile(
                title: "Privacy",
                leading: const Icon(Icons.shield),
                onPressed: (context) => Navigator.pushNamed(context, privacyRoute)
              )
            ]
          ),
          SettingsSection(
            title: "Miscellaneous",
            tiles: [
              SettingsTile(
                title: "About",
                leading: const Icon(Icons.info),
                onPressed: (context) => Navigator.pushNamed(context, aboutRoute)
              ),
              SettingsTile(
                title: "Open-Source licenses",
                leading: const Icon(Icons.description),
                onPressed: (context) => Navigator.pushNamed(context, licensesRoute)
              )
            ]
          ),
          // TODO: Maybe also have a switch somewhere
          ...(kDebugMode ? [
              SettingsSection(
                title: "Debugging",
                tiles: [
                  SettingsTile(
                    title: "Debugging options",
                    leading: const Icon(Icons.info),
                    onPressed: (context) => Navigator.pushNamed(context, debuggingRoute)
                  )
                ]
              )
            ] : []) 
        ]
      )
    );
  }
}
