import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:moxxyv2/shared/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({ Key? key }): super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(builder: (_) => const AppearancePage());
  
  // TODO(Unknown): Move this somewhere else to not mix UI and application logic
  Future<String?> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final backgroundPath = path.join(appDir.path, result.files.single.name);
    await File(result.files.single.path!).copy(backgroundPath);

    return backgroundPath;
  }

  Future<void> _setBackgroundImage(BuildContext context, PreferencesState state, String backgroundPath) async {
    // TODO(Unknown): Handle this in the PreferencesBloc
    final oldBackgroundImage = state.backgroundPath;
    if (oldBackgroundImage.isNotEmpty) {
      final file = File(oldBackgroundImage);

      if (file.existsSync()) {
        await file.delete();
      }
    }
    // TODO(Unknown): END

    // ignore: use_build_context_synchronously
    context.read<PreferencesBloc>().add(
      PreferencesChangedEvent(
        state.copyWith(backgroundPath: backgroundPath),
      ),
    );
  }

  Future<void> _removeBackgroundImage(BuildContext context, PreferencesState state) async {
    final backgroundPath = state.backgroundPath;
    if (backgroundPath.isEmpty) return;

    // TODO(Unknown): Move this into the [PreferencesBloc]
    final file = File(backgroundPath);
    if (file.existsSync()) {
      await file.delete();
    }
    // TODO(Unknown): END
 
    // ignore: use_build_context_synchronously
    context.read<PreferencesBloc>().add(
      PreferencesChangedEvent(
        state.copyWith(backgroundPath: ''),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Appearance'),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          darkBackgroundColor: const Color(0xff303030),
          contentPadding: const EdgeInsets.all(16),
          sections: [
            SettingsSection(
              title: 'Conversation Background',
              tiles: [
                SettingsTile(
                  title: 'Select background image',
                  subtitle: 'This image will be the background of all your chats',
                  onPressed: (context) async {
                    final backgroundPath = await _pickBackgroundImage();

                    if (backgroundPath != null) {
                      // ignore: use_build_context_synchronously
                      await _setBackgroundImage(context, state, backgroundPath);
                    }
                  },
                ),
                SettingsTile(
                  title: 'Remove background image',
                  onPressed: (context) {
                    showConfirmationDialog(
                      'Are you sure?',
                      'Are you sure you want to remove your conversation background image?',
                      context,
                      () async {
                        await _removeBackgroundImage(context, state);
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      }
                    );
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
