import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/bloc/preferences_bloc.dart";
import "package:moxxyv2/shared/preferences.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class _AutoDownloadSizes {
  final int value;
  final String text;

  const _AutoDownloadSizes(this.text, this.value);
}

class NetworkPage extends StatelessWidget {
  final List<_AutoDownloadSizes> _autoDownloadSizes = const [
    _AutoDownloadSizes("1MB", 1),
    _AutoDownloadSizes("5MB", 5),
    _AutoDownloadSizes("15MB", 15),
    _AutoDownloadSizes("100MB", 100),
    _AutoDownloadSizes("Always", -1),
  ];

  const NetworkPage({ Key? key }): super(key: key);
  
  Widget _buildFileSizeListItem(BuildContext context, String text, int value, bool selected) {
    final textTheme = Theme.of(context).textTheme.labelLarge;
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();

        final bloc = context.read<PreferencesBloc>();
        bloc.add(
          PreferencesChangedEvent(
            bloc.state.copyWith(maximumAutoDownloadSize: value)
          )
        );
      },
      child: selected
        ? IntrinsicWidth(
            child: Row(
              children: [
                Text(text, style: textTheme),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.check,
                    color: textTheme!.color
                  )
                ) 
              ]
            )
          )
        : Text(text, style: textTheme)
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple("Network"),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "Automatic Downloads",
              tiles: [
                SettingsTile(title: "Moxxy will automatically download files on..."),
                SettingsTile.switchTile(
                  title: "Wifi",
                  switchValue: state.autoDownloadWifi,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(autoDownloadWifi: value)
                    )
                  )
                ),
                SettingsTile.switchTile(
                  title: "Mobile Data",
                  switchValue: state.autoDownloadMobile,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(autoDownloadMobile: value)
                    )
                  )
                ),
                SettingsTile(
                  title: "Maximum Download Size",
                  subtitle: "The maximum file size for a file to be automatically downloaded",
                  subtitleMaxLines: 2,
                  onPressed: (context) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _autoDownloadSizes.length,
                            itemBuilder: (context, index) => _buildFileSizeListItem(
                              context,
                              _autoDownloadSizes[index].text,
                              _autoDownloadSizes[index].value,
                              _autoDownloadSizes[index].value == state.maximumAutoDownloadSize,
                            )
                          )
                        );
                      },
                      isDismissible: true
                    );
                  }
                ),
              ]
            )
          ]
        )
      )
    );
  }
}
