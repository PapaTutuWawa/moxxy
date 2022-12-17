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
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';

class StickersSettingsPage extends StatelessWidget {
  const StickersSettingsPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const StickersSettingsPage(),
    settings: const RouteSettings(
      name: stickersRoute,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // TODO(PapaTutuWawa): Allow managing sticker packs
    return Scaffold(
      appBar: BorderlessTopbar.simple(t.pages.settings.conversation.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => SettingsList(
          sections: [
            SettingsSection(
              title: Text('Stickers'),
              tiles: [
                SettingsTile.switchTile(
                  title: Text('Display stickers in chats'),
                  initialValue: state.enableStickers,
                  onToggle: (value) async {
                    context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(enableStickers: value),
                      ),
                    );
                  },
                ),
                SettingsTile.switchTile(
                  title: Text('Automatically download stickers'),
                  description: Text('If enabled, stickers are automatically downloaded when the sender is in your contact list.'),
                  initialValue: state.autoDownloadStickersFromContacts,
                  onToggle: (value) async {
                    context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(autoDownloadStickersFromContacts: value),
                      ),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text('Sticker packs'),
              tiles: [],
            ),
          ],
        ),
      ),
    );
  }
}
