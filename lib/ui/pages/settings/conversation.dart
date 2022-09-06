import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class ConversationSettingsPage extends StatelessWidget {

  const ConversationSettingsPage({ Key? key }): super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const ConversationSettingsPage(),
    settings: const RouteSettings(
      name: conversationSettingsRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Conversation'),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: const Text('New Conversations'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Mute new chats by default'),
                  initialValue: state.defaultMuteState,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(defaultMuteState: value),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
