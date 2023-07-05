import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/shared_media_controller.dart';
import 'package:moxxyv2/ui/widgets/shared_media_view.dart';

class StorageSharedMediaPage extends StatefulWidget {
  const StorageSharedMediaPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StorageSharedMediaPage(),
        settings: const RouteSettings(
          name: storageSharedMediaSettingsRoute,
        ),
      );

  @override
  StorageSharedMediaPageState createState() => StorageSharedMediaPageState();
}

class StorageSharedMediaPageState extends State<StorageSharedMediaPage> {
  final BidirectionalSharedMediaController _controller =
      BidirectionalSharedMediaController(null);

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
    return SharedMediaView(
      _controller,
      showBackButton: true,
      title: t.pages.settings.storage.mediaFiles,
    );
  }
}
