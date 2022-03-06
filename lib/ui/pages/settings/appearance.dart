import "dart:io";

import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/preferences/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";
import "package:file_picker/file_picker.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as path;

class AppearancePage extends StatelessWidget {
  const AppearancePage({ Key? key }): super(key: key);

  Future<String?> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image
    );

    if (result == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final backgroundPath = path.join(appDir.path, result.files.single.name);
    await File(result.files.single.path!).copy(backgroundPath);

    return backgroundPath;
  }

  void _setBackgroundImage(Store store, String backgroundPath) {
    store.dispatch(
      SetPreferencesAction(
        store.state.preferencesState.copyWith(
          backgroundPath: backgroundPath
        )
      )
    );
  }

  Future<void> _removeBackgroundImage(Store store) async {
    await File(store.state.preferencesState.backgroundPath).delete();

    store.dispatch(
      SetPreferencesAction(
        store.state.preferencesState.copyWith(
          backgroundPath: ""
        )
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Appearance"),
      body: StoreConnector<MoxxyState, Store>(
        converter: (store) => store,
        builder: (context, store) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16.0),
          sections: [
            SettingsSection(
              title: "Conversation Background",
              tiles: [
                SettingsTile(
                  title: "Select background image",
                  subtitle: "This image will be the background of all your chats",
                  onPressed: (context) async {
                    final backgroundPath = await _pickBackgroundImage();

                    if (backgroundPath != null) {
                      _setBackgroundImage(store, backgroundPath);
                    }
                  }
                ),
                SettingsTile(
                  title: "Remove background image",
                  onPressed: (context) {
                    showConfirmationDialog(
                      "Are you sure?",
                      "Are you sure you want to remove your conversation background image?",
                      context,
                      () async {
                        await _removeBackgroundImage(store);
                        Navigator.of(context).pop();
                      }
                    );
                  }
                )
              ]
            )
          ]
        )
      )
    );
  }
}
