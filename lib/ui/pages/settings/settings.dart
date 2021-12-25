import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";

import "package:flutter_settings_ui/flutter_settings_ui.dart";

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Settings"),
      body: SettingsList(
        // TODO: Seems hacky
        darkBackgroundColor: Color(0xff303030),
        contentPadding: EdgeInsets.all(16.0),
        sections: [
          SettingsSection(
            title: "Miscellaneous",
            tiles: [
              SettingsTile(
                title: "About",
                leading: Icon(Icons.info),
                onTap: () => Navigator.pushNamed(context, "/settings/about")
              ),
              SettingsTile(
                title: "Open-Source licenses",
                leading: Icon(Icons.description),
                onTap: () => Navigator.pushNamed(context, "/settings/licenses")
              )
            ]
          )
        ]
      )
    );
  }
}
