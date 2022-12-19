import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    return Scaffold(
      appBar: BorderlessTopbar.simple(t.pages.settings.stickers.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (_, prefs) => BlocBuilder<StickersBloc, StickersState>(
          builder: (__, stickers) => Padding(
            padding: EdgeInsets.zero,
            child: ListView.builder(
              itemCount: stickers.stickerPacks.length + 1,
              itemBuilder: (___, index) {
                if (index == 0) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(t.pages.settings.stickers.displayStickers),
                      
                      SettingsRow(
                        title: t.pages.settings.stickers.displayStickers,
                        suffix: Switch(
                          value: prefs.enableStickers,
                          onChanged: (value) {
                            context.read<PreferencesBloc>().add(
                              PreferencesChangedEvent(
                                prefs.copyWith(enableStickers: value),
                              ),
                            );
                          },
                        ),
                      ),

                      SettingsRow(
                        title: t.pages.settings.stickers.autoDownload,
                        description: t.pages.settings.stickers.autoDownloadBody,
                        suffix: Switch(
                          value: prefs.autoDownloadStickersFromContacts,
                          onChanged: (value) {
                            context.read<PreferencesBloc>().add(
                              PreferencesChangedEvent(
                                prefs.copyWith(autoDownloadStickersFromContacts: value),
                              ),
                            );
                          },
                        ),
                      ),

                      SettingsRow(
                        onTap: () {
                          GetIt.I.get<StickersBloc>().add(
                            StickerPackImportedEvent(),
                          );
                        },

                        title: t.pages.settings.stickers.importStickerPack,
                      ),

                      SectionTitle(t.pages.settings.stickers.stickerPacksSection),
                    ],
                  );
                }

                return SettingsRow(
                  title: stickers.stickerPacks[index - 1].name,
                  description: stickers.stickerPacks[index - 1].description,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  prefix: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      // TODO(PapaTutuWawa): Sticker pack thumbnails would be nice
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(radiusLarge),
                        child: ColoredBox(
                          color: Colors.white60,
                          child: Icon(
                            PhosphorIcons.stickerBold,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    GetIt.I.get<StickerPackBloc>().add(
                      LocallyAvailableStickerPackRequested(
                        stickers.stickerPacks[index - 1].id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
