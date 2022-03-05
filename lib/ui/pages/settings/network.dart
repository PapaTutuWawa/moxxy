import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/preferences/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class NetworkPage extends StatelessWidget {
  const NetworkPage({ Key? key }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Network"),
      body: StoreConnector<MoxxyState, Store>(
        converter: (store) => store,
        builder: (context, store) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "Automatic Downloads",
              tiles: [
                SettingsTile(title: "Moxxy will automatically download files on..."),
                SettingsTile.switchTile(
                  title: "Wifi",
                  switchValue: store.state.preferencesState.autoDownloadWifi,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        autoDownloadWifi: value
                      )
                    )
                  )
                ),
                SettingsTile.switchTile(
                  title: "Mobile Internet",
                  switchValue: store.state.preferencesState.autoDownloadMobile,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        autoDownloadMobile: value
                      )
                    )
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }
}
