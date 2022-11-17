import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:settings_ui/settings_ui.dart';

class _AutoDownloadSizes {

  const _AutoDownloadSizes(this.text, this.value);
  final int value;
  final String text;
}

const _autoDownloadSizes = <_AutoDownloadSizes>[
  _AutoDownloadSizes('1MB', 1),
  _AutoDownloadSizes('5MB', 5),
  _AutoDownloadSizes('15MB', 15),
  _AutoDownloadSizes('100MB', 100),
  _AutoDownloadSizes('Always', -1),
];

class NetworkPage extends StatelessWidget {
  const NetworkPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const NetworkPage(),
    settings: const RouteSettings(
      name: networkRoute,
    ),
  );
  
  Widget _buildFileSizeListItem(BuildContext context, String text, int value, bool selected) {
    final textTheme = Theme.of(context).textTheme.subtitle2;
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();

        final bloc = context.read<PreferencesBloc>();
        bloc.add(
          PreferencesChangedEvent(
            bloc.state.copyWith(maximumAutoDownloadSize: value),
          ),
        );
      },
      child: selected
        ? IntrinsicWidth(
            child: Row(
              children: [
                Text(text, style: textTheme),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check,
                    color: textTheme!.color,
                  ),
                ) 
              ],
            ),
          )
        : Text(text, style: textTheme),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(t.pages.settings.network.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: Text(t.pages.settings.network.automaticDownloadsSection),
              tiles: [
                SettingsTile(
                  title: Text(t.pages.settings.network.automaticDownloadsText),
                ),
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.network.wifi),
                  initialValue: state.autoDownloadWifi,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(autoDownloadWifi: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.network.mobileData),
                  initialValue: state.autoDownloadMobile,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(autoDownloadMobile: value),
                    ),
                  ),
                ),
                SettingsTile(
                  title: Text(t.pages.settings.network.automaticDownloadsMaximumSize),
                  description: Text(t.pages.settings.network.automaticDownloadsMaximumSizeSubtext),
                  onPressed: (context) {
                    showModalBottomSheet<dynamic>(
                      context: context,
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _autoDownloadSizes.length,
                            itemBuilder: (BuildContext context, int index) => _buildFileSizeListItem(
                              context,
                              _autoDownloadSizes[index].text,
                              _autoDownloadSizes[index].value,
                              _autoDownloadSizes[index].value == state.maximumAutoDownloadSize,
                            ),
                          ),
                        );
                      },
                      isDismissible: true,
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
