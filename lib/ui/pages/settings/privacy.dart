import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/preferences/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({ Key? key }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Privacy"),
      body: StoreConnector<MoxxyState, Store>(
        converter: (store) => store,
        builder: (context, store) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "General",
              tiles: [
                SettingsTile.switchTile(
                  title: "Show contact requests",
                  subtitle: "This will show people who added you to their contact list but sent no message yet",
                  subtitleMaxLines: 2,
                  switchValue: store.state.preferencesState.showSubscriptionRequests,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        showSubscriptionRequests: value
                      )
                    )
                  )
                ),
                SettingsTile.switchTile(
                  title: "Make profile picture public",
                  subtitle: "If enabled, everyone can see your profile picture. If disabled, only users on your contact list can see your profile picture.",
                  subtitleMaxLines: 3,
                  switchValue: store.state.preferencesState.isAvatarPublic,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        isAvatarPublic: value
                      )
                    )
                  )
                ),
                SettingsTile.switchTile(
                  title: "Auto-accept subscription requests",
                  subtitle: "If enabled, subscription requests will be automatically accepted if the user is in the contact list.",
                  subtitleMaxLines: 3,
                  switchValue: store.state.preferencesState.autoAcceptSubscriptionRequests,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        autoAcceptSubscriptionRequests: value
                      )
                    )
                  )
                )
              ]
            ),
            SettingsSection(
              title: "Conversation",
              tiles: [
                SettingsTile.switchTile(
                  title: "Send chat markers",
                  subtitle: "This will tell your conversation partner if you received or read a message",
                  subtitleMaxLines: 2,
                  switchValue: store.state.preferencesState.sendChatMarkers,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        sendChatMarkers: value
                      )
                    )
                  )
                ),
                SettingsTile.switchTile(
                  title: "Send chat states",
                  subtitle: "This will show your conversation partner if you are typing or looking at the chat",
                  subtitleMaxLines: 2,
                  switchValue: store.state.preferencesState.sendChatStates,
                  onToggle: (value) => store.dispatch(
                    SetPreferencesAction(
                      store.state.preferencesState.copyWith(
                        sendChatStates: value
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
