import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';

class StickersSettingsPage extends StatelessWidget {
  const StickersSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StickersSettingsPage(),
        settings: const RouteSettings(
          name: stickersRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersBloc, StickersState>(
      builder: (_, stickersState) => PopScope(
        canPop: !stickersState.isImportRunning,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(t.pages.settings.stickers.title),
                ),
                body: BlocBuilder<PreferencesCubit, PreferencesState>(
                  builder: (_, prefs) => Padding(
                    padding: EdgeInsets.zero,
                    child: ListView(
                      children: [
                        SectionTitle(
                          t.pages.settings.stickers.displayStickers,
                        ),
                        SettingsRow(
                          title: t.pages.settings.stickers.displayStickers,
                          suffix: Switch(
                            value: prefs.enableStickers,
                            onChanged: (value) {
                              context.read<PreferencesCubit>().change(
                                    prefs.copyWith(
                                      enableStickers: value,
                                    ),
                                  );
                            },
                          ),
                        ),
                        SettingsRow(
                          title: t.pages.settings.stickers.autoDownload,
                          description:
                              t.pages.settings.stickers.autoDownloadBody,
                          suffix: Switch(
                            value: prefs.autoDownloadStickersFromContacts,
                            onChanged: (value) {
                              context.read<PreferencesCubit>().change(
                                    prefs.copyWith(
                                      autoDownloadStickersFromContacts: value,
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
                        SettingsRow(
                          title: t.pages.settings.storage.manageStickers,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              stickerPacksRoute,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                curve: Curves.decelerate,
                opacity: stickersState.isImportRunning ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !stickersState.isImportRunning,
                  child: const ColoredBox(
                    color: Colors.black54,
                    child: Align(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
