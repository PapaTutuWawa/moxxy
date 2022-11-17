import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/settings/privacy/tile.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const PrivacyPage(),
    settings: const RouteSettings(
      name: privacyRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(t.pages.settings.privacy.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: Text(t.pages.settings.privacy.generalSection),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.privacy.showContactRequests),
                  description: Text(t.pages.settings.privacy.showContactRequestsSubtext),
                  initialValue: state.showSubscriptionRequests,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(showSubscriptionRequests: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.privacy.profilePictureVisibility),
                  description: Text(t.pages.settings.privacy.profilePictureVisibilitSubtext),
                  initialValue: state.isAvatarPublic,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(isAvatarPublic: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.privacy.autoAcceptSubscriptionRequests),
                  description: Text(t.pages.settings.privacy.autoAcceptSubscriptionRequestsSubtext),
                  initialValue: state.autoAcceptSubscriptionRequests,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(autoAcceptSubscriptionRequests: value),
                    ),
                  ),
                )
              ],
            ),
            SettingsSection(
              title: Text(t.pages.settings.privacy.conversationsSection),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.privacy.sendChatMarkers),
                  description: Text(t.pages.settings.privacy.sendChatMarkersSubtext),
                  initialValue: state.sendChatMarkers,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatMarkers: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.privacy.sendChatStates),
                  description: Text(t.pages.settings.privacy.sendChatStatesSubtext),
                  initialValue: state.sendChatStates,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatStates: value),
                    ),
                  ),
                )
              ],
            ),
            SettingsSection(
              title: Text(t.pages.settings.privacy.redirectsSection),
              tiles: [
                RedirectSettingsTile(
                  'Youtube',
                  'Invidious',
                  (state) => state.youtubeRedirect,
                  (state, value) => state.copyWith(youtubeRedirect: value),
                  (state) => state.enableYoutubeRedirect,
                  (state, value) => state.copyWith(enableYoutubeRedirect: value), 
                ),
                RedirectSettingsTile(
                  'Twitter',
                  'Nitter',
                  (state) => state.twitterRedirect,
                  (state, value) => state.copyWith(twitterRedirect: value),
                  (state) => state.enableTwitterRedirect,
                  (state, value) => state.copyWith(enableTwitterRedirect: value), 
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
