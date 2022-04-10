import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/bloc/preferences_bloc.dart";
import "package:moxxyv2/shared/preferences.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:drop_down_list/drop_down_list.dart";

class NetworkPage extends StatelessWidget {
  const NetworkPage({ Key? key }): super(key: key);

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
                    // TODO: This does not work on dark mode
                    DropDownState(
                      DropDown(
                        submitButtonText: "Okay",
                        submitButtonColor: const Color.fromRGBO(70, 76, 222, 1),
                        bottomSheetTitle: "Maximum File Size",
                        searchBackgroundColor: Colors.black12,
                        dataList: [
                          SelectedListItem(state.maximumAutoDownloadSize == 1, "1MB"),
                          SelectedListItem(state.maximumAutoDownloadSize == 5, "5MB"),
                          SelectedListItem(state.maximumAutoDownloadSize == 15, "15MB"),
                          SelectedListItem(state.maximumAutoDownloadSize == 100, "100MB"),
                          SelectedListItem(state.maximumAutoDownloadSize == -1, "Always")
                        ],
                        selectedItem: (String selected) {
                          int value = -1;
                          switch (selected) {
                            case "1MB": {
                              value = 1;
                            }
                            break;
                            case "5MB": {
                              value = 5;
                            }
                            break;
                            case "15MB": {
                              value = 15;
                            }
                            break;
                            case "100MB": {
                              value = 100;
                            }
                            break;
                            default: {
                              value = -1;
                            }
                            break;
                          }

                          context.read<PreferencesBloc>().add(
                            PreferencesChangedEvent(
                              state.copyWith(maximumAutoDownloadSize: value)
                            )
                          );
                        },
                        enableMultipleSelection: false,
                        searchController: TextEditingController()
                      ),
                    ).showModal(context);
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
