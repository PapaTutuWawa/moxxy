import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({ Key? key }): super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const PrivacyPage(),
    settings: const RouteSettings(
      name: privacyRoute,
    ),
  );

  @override
  PrivacyPageState createState() => PrivacyPageState();
}

class PrivacyPageState extends State<PrivacyPage> {

  PrivacyPageState() : _controller = TextEditingController();
  TextEditingController _controller;
  String? errorText;

  bool _validateUrl() {
    final value = _controller.text;
    return value.isNotEmpty && Uri.tryParse(value) != null;
  }
  
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
            SettingsSection(
              title: Text('Redirects'),
              tiles: [
                SettingsTile(
                  title: Text('Youtube Redirect'),
                  description: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text('This will redirect Youtube links that you tap to a proxy service, e.g. Invidious'),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Currently selected: ${state.youtubeRedirect}'),
                      ),
                    ],
                  ),
                  onPressed: (context) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text('Youtube Redirect'),
                        content: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomTextField(
                                cornerRadius: textfieldRadiusRegular,
                                borderColor: primaryColor,
                                borderWidth: 1,
                                enableIMEFeatures: false,
                                controller: _controller,
                                errorText: errorText,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Okay'),
                            onPressed: () {
                              if (_validateUrl()) {
                                // TODO(PapaTutuWawa): Change settings
                                Navigator.of(context).pop();
                                return;
                              }

                              // TODO(PapaTutuWawa): Manage this via a BLoC
                              setState(() {
                                errorText = 'Invalid Url';
                                print('lol');
                              });
                            },
                          ),
                          TextButton(
                            child: const Text('Less okay'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                  trailing: Switch(
                    value: state.enableYoutubeRedirect,
                    onChanged: (value) {
                      if (state.youtubeRedirect.isEmpty) {
                        showInfoDialog(
                          'Cannot enable Youtube redirects',
                          'You must first set a proxy service to redirect to. To do so, tap the field next to the switch.',
                          context,
                        );
                        return;
                      }

                      context.read<PreferencesBloc>().add(
                        PreferencesChangedEvent(
                          state.copyWith(enableYoutubeRedirect: value),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
