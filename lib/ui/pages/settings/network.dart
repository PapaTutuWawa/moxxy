import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';

class _AutoDownloadSizes {
  const _AutoDownloadSizes(this.text, this.value);
  final int value;
  final String text;
}

const _autoDownloadSizes = <_AutoDownloadSizes>[
  _AutoDownloadSizes('1MB', 1),
  _AutoDownloadSizes('5MB', 5),
  _AutoDownloadSizes('15MB', 15),
  _AutoDownloadSizes('100MB', 100),
  _AutoDownloadSizes('', -1),
];

class AutoDownloadSizeDialog extends StatefulWidget {
  const AutoDownloadSizeDialog({
    required this.selectedValueInitial,
    super.key,
  });
  final int selectedValueInitial;

  @override
  AutoDownloadSizeDialogState createState() => AutoDownloadSizeDialogState();
}

class AutoDownloadSizeDialogState extends State<AutoDownloadSizeDialog> {
  int selection = -1;

  @override
  void initState() {
    super.initState();

    selection = widget.selectedValueInitial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 12,
      ),
      content: SingleChildScrollView(
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: _autoDownloadSizes
              .map(
                (size) => TableRow(
                  children: [
                    Text(
                      size.value == -1
                          ? t.pages.settings.network.automaticDownloadAlways
                          : size.text,
                    ),
                    Checkbox(
                      value: size.value == selection,
                      onChanged: (value) {
                        if (size.value == selection) return;

                        setState(() => selection = size.value);
                      },
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(selection),
          child: Text(t.global.dialogAccept),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.global.dialogCancel),
        ),
      ],
    );
  }
}

class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const NetworkPage(),
        settings: const RouteSettings(
          name: networkRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.network.title),
      ),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            SectionTitle(t.pages.settings.network.automaticDownloadsSection),
            SettingsRow(
              title: t.pages.settings.network.automaticDownloadsText,
            ),
            SettingsRow(
              title: t.pages.settings.network.wifi,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              suffix: Switch(
                value: state.autoDownloadWifi,
                onChanged: (value) => context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(autoDownloadWifi: value),
                      ),
                    ),
              ),
            ),
            SettingsRow(
              title: t.pages.settings.network.mobileData,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              suffix: Switch(
                value: state.autoDownloadMobile,
                onChanged: (value) => context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(autoDownloadMobile: value),
                      ),
                    ),
              ),
            ),
            SettingsRow(
              title: t.pages.settings.network.automaticDownloadsMaximumSize,
              description:
                  t.pages.settings.network.automaticDownloadsMaximumSizeSubtext,
              onTap: () async {
                final result = await showDialog<int>(
                  context: context,
                  builder: (context) => AutoDownloadSizeDialog(
                    selectedValueInitial: state.maximumAutoDownloadSize,
                  ),
                );
                if (result == null) return;
                if (state.maximumAutoDownloadSize == result) return;

                // ignore: use_build_context_synchronously
                context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(maximumAutoDownloadSize: result),
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
