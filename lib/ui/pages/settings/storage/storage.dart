import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart' as nav;
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/stacked_bar_chart.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum OlderThan {
  all(0),
  oneWeek(7 * 24 * 60 * 60 * 1000),
  oneMonth(31 * 24 * 60 * 60 * 1000);

  const OlderThan(this.milliseconds);

  final int milliseconds;
}

class DeleteMediaDialog extends StatefulWidget {
  const DeleteMediaDialog({
    super.key,
  });

  @override
  DeleteMediaDialogState createState() => DeleteMediaDialogState();
}

class DeleteMediaDialogState extends State<DeleteMediaDialog> {
  OlderThan _selection = OlderThan.oneWeek;

  Widget _optionRow(OlderThan value, String text) {
    return InkWell(
      onTap: () {
        setState(() => _selection = value);
      },
      child: Row(
        children: [
          Radio(
            value: value,
            groupValue: _selection,
            onChanged: (_) {
              setState(() => _selection = value);
            },
          ),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.pages.settings.storage.removeOldMediaDialog.title),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(textfieldRadiusRegular),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(
              await showConfirmationDialog(
                t.pages.settings.storage.removeOldMediaDialog.title,
                t.pages.settings.storage.removeOldMediaDialog.confirmation.body,
                context,
                affirmativeText:
                    t.pages.settings.storage.removeOldMediaDialog.delete,
                destructive: true,
              )
                  ? _selection
                  : null,
            );
          },
          child: Text(
            t.pages.settings.storage.removeOldMediaDialog.delete,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            t.global.dialogCancel,
          ),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _optionRow(
            OlderThan.all,
            t.pages.settings.storage.removeOldMediaDialog.options.all,
          ),
          _optionRow(
            OlderThan.oneWeek,
            t.pages.settings.storage.removeOldMediaDialog.options.oneWeek,
          ),
          _optionRow(
            OlderThan.oneMonth,
            t.pages.settings.storage.removeOldMediaDialog.options.oneMonth,
          ),
        ],
      ),
    );
  }
}

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StorageSettingsPage(),
        settings: const RouteSettings(
          name: storageSettingsRoute,
        ),
      );

  @override
  StorageSettingsPageState createState() => StorageSettingsPageState();
}

class StorageSettingsPageState extends State<StorageSettingsPage> {
  /// [StreamController] for the "Storage used: " label. The broadcast values
  /// are the storage used by media files (NOT stickers). As such, the total, assuming
  /// `usage` is a value received from the stream, is `usage + _stickersUsage`.
  final StreamController<int> _controller = StreamController<int>.broadcast();

  /// Cached sticker usage. The used storage by sticker packs cannot change from
  /// this page, so caching it is fin.
  int _stickerUsage = 0;

  @override
  void initState() {
    super.initState();

    _asyncInit();
  }

  Future<void> _asyncInit() async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetStorageUsageCommand(),
        ) as GetStorageUsageEvent;

    _stickerUsage = result.stickerUsage;
    _controller.add(result.mediaUsage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.settings.storage.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: StreamBuilder<int>(
                stream: _controller.stream,
                builder: (context, snapshot) {
                  final size = snapshot.hasData
                      ? fileSizeToString(snapshot.data! + _stickerUsage)
                      : t.pages.settings.storage.sizePlaceholder;

                  return Center(
                    child: Text(
                      t.pages.settings.storage.storageUsed(size: size),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                },
              ),
            ),
            Center(
              child: StreamBuilder<int>(
                stream: _controller.stream,
                builder: (context, snapshot) => StackedBarChart(
                  width: MediaQuery.of(context).size.width * 0.8,
                  items: [
                    // TODO: i18n
                    BartChartItem(
                      'Media',
                      snapshot.data ?? 0,
                      Colors.red,
                    ),
                    BartChartItem(
                      'Stickers',
                      _stickerUsage,
                      Colors.blue,
                    ),
                  ],
                  showPlaceholderBars: !snapshot.hasData,
                ),
              ),
            ),
            Center(
              child: TextButton(
                child: Text(t.pages.settings.storage.viewMediaFiles),
                onPressed: () {
                  context.read<nav.NavigationBloc>().add(
                        nav.PushedNamedEvent(
                          const nav.NavigationDestination(
                            storageSharedMediaSettingsRoute,
                          ),
                        ),
                      );
                },
              ),
            ),
            SectionTitle(t.pages.settings.storage.storageManagement),
            SettingsRow(
              title: t.pages.settings.storage.removeOldMedia.title,
              description: t.pages.settings.storage.removeOldMedia.description,
              onTap: () async {
                final result = await showDialog<OlderThan>(
                  context: context,
                  builder: (context) => const DeleteMediaDialog(),
                );
                if (result != null) {
                  final deleteResult =
                      // ignore: cast_nullable_to_non_nullable
                      await MoxplatformPlugin.handler.getDataSender().sendData(
                            DeleteOldMediaFilesCommand(
                              timeOffset: result.milliseconds,
                            ),
                            awaitable: true,
                          ) as DeleteOldMediaFilesDoneEvent;

                  // Update the display
                  _controller.add(
                    deleteResult.newUsage,
                  );

                  // Show the new conversations list
                  GetIt.I.get<ConversationsBloc>().add(
                        ConversationsSetEvent(deleteResult.conversations),
                      );
                }
              },
            ),
            SettingsRow(
              // TODO: i18n
              title: 'Manage sticker packs',
              onTap: () {
                Navigator.of(context).pushNamed(stickersRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}
