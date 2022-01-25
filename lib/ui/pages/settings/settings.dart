import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/account/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_redux/flutter_redux.dart";

class _SettingsPageViewModel {
  final void Function() performLogout;

  const _SettingsPageViewModel({ required this.performLogout });
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({ Key? key }) : super(key: key);

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
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "Account",
              tiles: [
                SettingsTile(
                  title: "Sign out",
                  leading: const Icon(Icons.logout),
                  onPressed: (context) => showConfirmationDialog(
                    "Sign Out",
                    "You are about to sign out. Proceed?",
                    context,
                    viewModel.performLogout
                  )
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
            )
          ]
        )
      )
    );
  }
}
