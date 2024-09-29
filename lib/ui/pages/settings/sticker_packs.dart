import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/sticker_pack_controller.dart';
import 'package:moxxyv2/ui/state/sticker_pack.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StickerPacksSettingsPage extends StatefulWidget {
  const StickerPacksSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StickerPacksSettingsPage(),
        settings: const RouteSettings(
          name: stickerPacksRoute,
        ),
      );

  @override
  StickerPacksSettingsState createState() => StickerPacksSettingsState();
}

class StickerPacksSettingsState extends State<StickerPacksSettingsPage> {
  final BidirectionalStickerPackController _controller =
      BidirectionalStickerPackController(false);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.stickerPacks.title),
      ),
      body: StreamBuilder<List<StickerPack>>(
        stream: _controller.dataStream,
        initialData: const [],
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final sizeString = fileSizeToString(
                snapshot.data![index].size,
              );
              return SettingsRow(
                titleWidget: Row(
                  children: [
                    Expanded(
                      child: Text(
                        snapshot.data![index].name,
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
                description: snapshot.data![index].description,
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
                          PhosphorIconsRegular.sticker,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  GetIt.I.get<StickerPackCubit>().requestLocalStickerPack(
                        snapshot.data![index].id,
                      );
                },
              );
            },
          );
        },
      ),
    );
  }
}
