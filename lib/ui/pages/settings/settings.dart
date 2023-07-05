import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const SettingsPage(),
        settings: const RouteSettings(
          name: settingsRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.settings.settings.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        buildWhen: (prev, next) => prev.showDebugMenu != next.showDebugMenu,
        builder: (context, state) => ListView(
          children: [
            SectionTitle(t.pages.settings.settings.general),
            SettingsRow(
              title: t.pages.settings.appearance.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.brush),
              ),
              onTap: () {
                Navigator.pushNamed(context, appearanceRoute);
              },
            ),
            SectionTitle(t.pages.settings.settings.conversationsSection),
            SettingsRow(
              title: t.pages.settings.settings.conversationsSection,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.chat_bubble),
              ),
              onTap: () {
                Navigator.pushNamed(context, conversationSettingsRoute);
              },
            ),
            SettingsRow(
              title: t.pages.settings.stickers.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(PhosphorIcons.stickerBold),
              ),
              onTap: () {
                Navigator.pushNamed(context, stickersRoute);
              },
            ),
            SettingsRow(
              title: t.pages.settings.storage.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.storage),
              ),
              onTap: () {
                Navigator.pushNamed(context, storageSettingsRoute);
              },
            ),
            SettingsRow(
              title: t.pages.settings.network.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.network_wifi),
              ),
              onTap: () {
                Navigator.pushNamed(context, networkRoute);
              },
            ),
            SettingsRow(
              title: t.pages.settings.privacy.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.shield),
              ),
              onTap: () {
                Navigator.pushNamed(context, privacyRoute);
              },
            ),
            SettingsRow(
              title: t.pages.blocklist.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.block),
              ),
              onTap: () {
                GetIt.I.get<BlocklistBloc>().add(
                      BlocklistRequestedEvent(),
                    );
              },
            ),
            SectionTitle(t.pages.settings.settings.accountSection),
            SettingsRow(
              title: t.pages.settings.settings.signOut,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.logout),
              ),
              onTap: () async {
                final result = await showConfirmationDialog(
                  t.pages.settings.settings.signOutConfirmTitle,
                  t.pages.settings.settings.signOutConfirmBody,
                  context,
                );

                if (result) {
                  GetIt.I.get<PreferencesBloc>().add(SignedOutEvent());
                }
              },
            ),
            SectionTitle(t.pages.settings.settings.miscellaneousSection),
            SettingsRow(
              title: t.pages.settings.about.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.info),
              ),
              onTap: () {
                Navigator.pushNamed(context, aboutRoute);
              },
            ),
            SettingsRow(
              title: t.pages.settings.licenses.title,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.info),
              ),
              onTap: () {
                Navigator.pushNamed(context, licensesRoute);
              },
            ),
            if (kDebugMode || state.showDebugMenu)
              SectionTitle(t.pages.settings.settings.debuggingSection),
            if (kDebugMode || state.showDebugMenu)
              SettingsRow(
                title: t.pages.settings.debugging.title,
                prefix: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.info),
                ),
                onTap: () {
                  Navigator.pushNamed(context, debuggingRoute);
                },
              ),
          ],
        ),
      ),
    );
  }
}
