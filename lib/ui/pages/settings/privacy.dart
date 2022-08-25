import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({ Key? key }): super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const PrivacyPage(),
    settings: const RouteSettings(
      name: privacyRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Privacy'),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: const Text('General'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Show contact requests'),
                  description: const Text('This will show people who added you to their contact list but sent no message yet'),
                  initialValue: state.showSubscriptionRequests,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(showSubscriptionRequests: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: const Text('Make profile picture public'),
                  description: const Text('If enabled, everyone can see your profile picture. If disabled, only users on your contact list can see your profile picture.'),
                  initialValue: state.isAvatarPublic,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(isAvatarPublic: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: const Text('Auto-accept subscription requests'),
                  description: const Text('If enabled, subscription requests will be automatically accepted if the user is in the contact list.'),
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
              title: const Text('Conversation'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Send chat markers'),
                  description: const Text('This will tell your conversation partner if you received or read a message'),
                  initialValue: state.sendChatMarkers,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatMarkers: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: const Text('Send chat states'),
                  description: const Text('This will show your conversation partner if you are typing or looking at the chat'),
                  initialValue: state.sendChatStates,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(sendChatStates: value),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
