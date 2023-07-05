import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart' as nav;
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

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
  final StreamController<int> _controller = StreamController<int>();

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

    _controller.add(result.usage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.settings.storage.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            StreamBuilder<int>(
              stream: _controller.stream,
              builder: (context, snapshot) {
                final description = snapshot.hasData
                    ? fileSizeToString(snapshot.data!)
                    : t.pages.settings.storage.wait;

                return SettingsRow(
                  title: t.pages.settings.storage.storageUsed,
                  description: description,
                  onTap: () {
                    context.read<nav.NavigationBloc>().add(
                          nav.PushedNamedEvent(
                            const nav.NavigationDestination(
                              storageSharedMediaSettingsRoute,
                            ),
                          ),
                        );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
