import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/sticker_pack_controller.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StickersSettingsPage extends StatefulWidget {
  const StickersSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StickersSettingsPage(),
        settings: const RouteSettings(
          name: stickersRoute,
        ),
      );

  @override
  StickersSettingsPageState createState() => StickersSettingsPageState();
}

class StickersSettingsPageState extends State<StickersSettingsPage> {
  final BidirectionalStickerPackController _controller =
      BidirectionalStickerPackController();

  @override
  void initState() {
    super.initState();

    _controller.fetchOlderData();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersBloc, StickersState>(
      builder: (_, stickersState) => WillPopScope(
        onWillPop: () async {
          return !stickersState.isImportRunning;
        },
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              // TODO: This is very ugly. Rework
              child: Scaffold(
                appBar: BorderlessTopbar.title(t.pages.settings.stickers.title),
                body: BlocBuilder<PreferencesBloc, PreferencesState>(
                  builder: (_, prefs) => Padding(
                    padding: EdgeInsets.zero,
                    child: StreamBuilder<List<StickerPack>>(
                      stream: _controller.dataStream,
                      initialData: const [],
                      builder: (context, snapshot) {
                        return ListView.builder(
                          controller: _controller.scrollController,
                          itemCount: snapshot.data!.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionTitle(
                                    t.pages.settings.stickers.displayStickers,
                                  ),
                                  SettingsRow(
                                    title: t.pages.settings.stickers
                                        .displayStickers,
                                    suffix: Switch(
                                      value: prefs.enableStickers,
                                      onChanged: (value) {
                                        context.read<PreferencesBloc>().add(
                                              PreferencesChangedEvent(
                                                prefs.copyWith(
                                                  enableStickers: value,
                                                ),
                                              ),
                                            );
                                      },
                                    ),
                                  ),
                                  SettingsRow(
                                    title:
                                        t.pages.settings.stickers.autoDownload,
                                    description: t.pages.settings.stickers
                                        .autoDownloadBody,
                                    suffix: Switch(
                                      value: prefs
                                          .autoDownloadStickersFromContacts,
                                      onChanged: (value) {
                                        context.read<PreferencesBloc>().add(
                                              PreferencesChangedEvent(
                                                prefs.copyWith(
                                                  autoDownloadStickersFromContacts:
                                                      value,
                                                ),
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
                                    title: t.pages.settings.stickers
                                        .importStickerPack,
                                  ),
                                  SectionTitle(
                                    t.pages.settings.stickers
                                        .stickerPacksSection,
                                  ),
                                  if (snapshot.data!.isEmpty)
                                    SettingsRow(
                                      title: t.pages.conversation
                                          .stickerPickerNoStickersLine1,
                                    ),
                                ],
                              );
                            }

                            final sizeString = fileSizeToString(
                              snapshot.data![index - 1].size,
                            );
                            return SettingsRow(
                              titleWidget: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      snapshot.data![index - 1].name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    t.pages.settings.stickers
                                        .stickerPackSize(size: sizeString),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              description:
                                  snapshot.data![index - 1].description,
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
                                        snapshot.data![index - 1].id,
                                      ),
                                    );
                              },
                            );
                          },
                        );
                      },
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
