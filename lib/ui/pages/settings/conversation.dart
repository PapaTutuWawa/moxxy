import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:settings_ui/settings_ui.dart';

class ConversationSettingsPage extends StatelessWidget {
  const ConversationSettingsPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const ConversationSettingsPage(),
    settings: const RouteSettings(
      name: conversationSettingsRoute,
    ),
  );

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

  Future<void> _removeBackgroundImage(BuildContext context, PreferencesState state) async {
    final backgroundPath = state.backgroundPath;
    if (backgroundPath.isEmpty) return;

    // TODO(Unknown): Move this into the [PreferencesBloc]
    final file = File(backgroundPath);
    if (file.existsSync()) {
      await file.delete();
    }
    // TODO(Unknown): END

    // Remove from the cache
    // TODO(PapaTutuWawa): Invalidate the cache
    
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
      appBar: BorderlessTopbar.simple(t.pages.settings.conversation.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: Text(t.pages.settings.conversation.appearance),
              tiles: [
                SettingsTile(
                  title: Text(t.pages.settings.conversation.selectBackgroundImage),
                  description: Text(t.pages.settings.conversation.selectBackgroundImageDescription),
                  onPressed: (context) async {
                    final backgroundPath = await _pickBackgroundImage();

                    if (backgroundPath != null) {
                      // ignore: use_build_context_synchronously
                      context.read<CropBackgroundBloc>().add(
                        CropBackgroundRequestedEvent(backgroundPath),
                      );
                    }
                  },
                ),
                SettingsTile(
                  title: Text(t.pages.settings.conversation.removeBackgroundImage),
                  onPressed: (context) async {
                    final result = await showConfirmationDialog(
                      t.pages.settings.conversation.removeBackgroundImageConfirmTitle,
                      t.pages.settings.conversation.removeBackgroundImageConfirmBody,
                      context,
                    );

                    if (result) {
                      // ignore: use_build_context_synchronously
                      await _removeBackgroundImage(context, state);
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(t.pages.settings.conversation.newChatsSection),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.conversation.newChatsMuteByDefault),
                  initialValue: state.defaultMuteState,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(defaultMuteState: value),
                    ),
                  ),
                ),
                SettingsTile.switchTile(
                  title: Text(t.pages.settings.conversation.newChatsE2EE),
                  initialValue: state.enableOmemoByDefault,
                  onToggle: (value) => context.read<PreferencesBloc>().add(
                    PreferencesChangedEvent(
                      state.copyWith(enableOmemoByDefault: value),
                    ),
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
