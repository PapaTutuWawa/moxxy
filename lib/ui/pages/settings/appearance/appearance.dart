import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

Widget _buildLanguageOption(
    BuildContext context, String localeCode, PreferencesState state) {
  final selected = state.languageLocaleCode == localeCode;
  return SimpleDialogOption(
    onPressed: () => Navigator.pop(context, localeCode),
    child: Flex(
      direction: Axis.horizontal,
      children: [
        Text(
          localeCodeToLanguageName(localeCode),
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        ...selected
            ? [
                const Spacer(),
                const Icon(Icons.check),
              ]
            : [],
      ],
    ),
  );
}

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const AppearanceSettingsPage(),
        settings: const RouteSettings(
          name: appearanceRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(t.pages.settings.appearance.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            SectionTitle(t.pages.settings.appearance.languageSection),
            SettingsRow(
              title: t.pages.settings.appearance.language,
              description: t.pages.settings.appearance.languageSubtext(
                selectedLanguage:
                    localeCodeToLanguageName(state.languageLocaleCode),
              ),
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(textfieldRadiusRegular),
                      ),
                      title: Text(t.pages.settings.appearance.language),
                      children: [
                        _buildLanguageOption(context, 'default', state),
                        _buildLanguageOption(context, 'de', state),
                        _buildLanguageOption(context, 'en', state),
                      ],
                    );
                  },
                );

                if (result == null) {
                  // Do nothing as the dialog was dismissed
                  return;
                }

                // Change preferences and set the app's locale
                // ignore: use_build_context_synchronously
                context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(languageLocaleCode: result),
                      ),
                    );

                if (result == 'default') {
                  LocaleSettings.useDeviceLocale();
                } else {
                  LocaleSettings.setLocaleRaw(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
