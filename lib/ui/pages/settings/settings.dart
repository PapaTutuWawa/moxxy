import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/account/actions.dart";

import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_redux/flutter_redux.dart";

class _SettingsPageViewModel {
  final void Function() performLogout;

  _SettingsPageViewModel({ required this.performLogout });
}

class SettingsPage extends StatelessWidget {
  void _showLogoutDialog(BuildContext context, _SettingsPageViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Sign Out"),
        content: Text("You are about to sign out. Proceed?"),
        actions: [
          TextButton(
            child: Text("Yes"),
            onPressed: viewModel.performLogout
          ),
          TextButton(
            child: Text("No"),
            onPressed: Navigator.of(context).pop
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Settings"),
      body: StoreConnector<MoxxyState, _SettingsPageViewModel>(
        converter: (store) => _SettingsPageViewModel(
          performLogout: () => store.dispatch(PerformLogoutAction())
        ),
        builder: (context, viewModel) => SettingsList(
          // TODO: Seems hacky
          darkBackgroundColor: Color(0xff303030),
          contentPadding: EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "Account",
              tiles: [
                SettingsTile(
                  title: "Sign out",
                  leading: Icon(Icons.logout),
                  onTap: () => this._showLogoutDialog(context, viewModel)
                )
              ]
            ),
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
      )
    );
  }
}
