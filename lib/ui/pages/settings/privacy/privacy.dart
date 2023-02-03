import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/settings/privacy/tile.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

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
        builder: (context, state) => ListView(
          children: [
            SectionTitle(t.pages.settings.privacy.generalSection),

            SettingsRow(
              title: t.pages.settings.privacy.showContactRequests,
              description: t.pages.settings.privacy.showContactRequestsSubtext,
              suffix: Switch(
                value: state.showSubscriptionRequests,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(showSubscriptionRequests: value),
                    ),
                  );
                },
              ),
            ),
            SettingsRow(
              title: t.pages.settings.privacy.profilePictureVisibility,
              description: t.pages.settings.privacy.profilePictureVisibilitSubtext,
              suffix: Switch(
                value: state.isAvatarPublic,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(isAvatarPublic: value),
                    ),
                  );
                },
              ),
            ),
            SettingsRow(
              title: t.pages.settings.privacy.stickersPrivacy,
              description: t.pages.settings.privacy.stickersPrivacySubtext,
              suffix: Switch(
                value: state.isStickersNodePublic,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(isStickersNodePublic: value),
                    ),
                  );
                },
              ),
            ),

            SectionTitle(t.pages.settings.privacy.conversationsSection),
            SettingsRow(
              title: t.pages.settings.privacy.sendChatMarkers,
              description: t.pages.settings.privacy.sendChatMarkersSubtext,
              suffix: Switch(
                value: state.sendChatMarkers,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatMarkers: value),
                    ),
                  );
                },
              ),
            ),
            SettingsRow(
              title: t.pages.settings.privacy.sendChatStates,
              description: t.pages.settings.privacy.sendChatStatesSubtext,
              suffix: Switch(
                value: state.sendChatStates,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatStates: value),
                    ),
                  );
                },
              ),
            ),

            SectionTitle(t.pages.settings.privacy.redirectsSection),
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
      ),
    );
  }
}
