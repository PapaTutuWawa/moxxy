import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
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
      appBar: BorderlessTopbar.simple(t.pages.settings.stickers.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (_, state) => BlocBuilder<StickersBloc, StickersState>(
          builder: (__, stickers) => SettingsList(
            sections: [
              SettingsSection(
                title: Text(t.pages.settings.stickers.stickerSection),
                tiles: [
                  SettingsTile.switchTile(
                    title: Text(t.pages.settings.stickers.displayStickers),
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
                    title: Text(t.pages.settings.stickers.autoDownload),
                    description: Text(t.pages.settings.stickers.autoDownloadBody),
                    initialValue: state.autoDownloadStickersFromContacts,
                    onToggle: (value) async {
                      context.read<PreferencesBloc>().add(
                        PreferencesChangedEvent(
                          state.copyWith(autoDownloadStickersFromContacts: value),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    title: Text(t.pages.settings.stickers.importStickerPack),
                    onPressed: (context) {
                      GetIt.I.get<StickersBloc>().add(
                        StickerPackImportedEvent(),
                      );
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: Text(t.pages.settings.stickers.stickerPacksSection),
                tiles: stickers.stickerPacks
                  .map((sp) => SettingsTile(
                    title: Text(sp.name),
                    onPressed: (context) {
                      GetIt.I.get<StickerPackBloc>().add(
                        LocallyAvailableStickerPackRequested(
                          sp.id,
                        ),
                      );
                    },
                  ),).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
