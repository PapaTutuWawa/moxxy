import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/cropbackground_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ConversationSettingsPage extends StatelessWidget {
  const ConversationSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const ConversationSettingsPage(),
        settings: const RouteSettings(
          name: conversationSettingsRoute,
        ),
      );

  // TODO(Unknown): Move this somewhere else to not mix UI and application logic
  Future<String?> _pickBackgroundImage() async {
    final result = await safePickFiles(
      FileType.image,
      allowMultiple: false,
    );

    if (result == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final backgroundPath = path.join(appDir.path, result.files.single.name);
    await File(result.files.single.path!).copy(backgroundPath);

    return backgroundPath;
  }

  Future<void> _removeBackgroundImage(
    BuildContext context,
    PreferencesState state,
  ) async {
    final backgroundPath = state.backgroundPath;
    if (backgroundPath.isEmpty) return;

    // TODO(Unknown): Move this into the [PreferencesBloc]
    final file = File(backgroundPath);
    if (file.existsSync()) {
      await file.delete();
    }
    // TODO(Unknown): END

    // Remove from the cache
    // TODO(PapaTutuWawa): Invalidate the cache

    // ignore: use_build_context_synchronously
    context.read<PreferencesBloc>().add(
          PreferencesChangedEvent(
            state.copyWith(backgroundPath: ''),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.settings.conversation.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            SectionTitle(t.pages.settings.conversation.appearance),
            SettingsRow(
              title: t.pages.settings.conversation.selectBackgroundImage,
              description: t
                  .pages.settings.conversation.selectBackgroundImageDescription,
              onTap: () async {
                final backgroundPath = await _pickBackgroundImage();

                if (backgroundPath != null) {
                  // ignore: use_build_context_synchronously
                  context.read<CropBackgroundBloc>().add(
                        CropBackgroundRequestedEvent(backgroundPath),
                      );
                }
              },
            ),
            SettingsRow(
              title: t.pages.settings.conversation.removeBackgroundImage,
              onTap: () async {
                final result = await showConfirmationDialog(
                  t.pages.settings.conversation
                      .removeBackgroundImageConfirmTitle,
                  t.pages.settings.conversation
                      .removeBackgroundImageConfirmBody,
                  context,
                );

                if (result) {
                  // ignore: use_build_context_synchronously
                  await _removeBackgroundImage(context, state);
                }
              },
            ),
            SectionTitle(t.pages.settings.conversation.behaviourSection),
            SettingsRow(
              title: t.pages.settings.conversation.contactsIntegration,
              description:
                  t.pages.settings.conversation.contactsIntegrationBody,
              suffix: Switch(
                value: state.enableContactIntegration,
                onChanged: (value) async {
                  // Ensure that we have the permission before changing the value
                  if (value &&
                      await Permission.contacts.status ==
                          PermissionStatus.denied) {
                    if (!(await Permission.contacts.request().isGranted)) {
                      return;
                    }
                  }

                  // ignore: use_build_context_synchronously
                  context.read<PreferencesBloc>().add(
                        PreferencesChangedEvent(
                          state.copyWith(enableContactIntegration: value),
                        ),
                      );
                },
              ),
            ),
            SectionTitle(t.pages.settings.conversation.newChatsSection),
            SettingsRow(
              title: t.pages.settings.conversation.newChatsMuteByDefault,
              suffix: Switch(
                value: state.defaultMuteState,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                        PreferencesChangedEvent(
                          state.copyWith(defaultMuteState: value),
                        ),
                      );
                },
              ),
            ),
            SettingsRow(
              title: t.pages.settings.conversation.newChatsE2EE,
              suffix: Switch(
                value: state.enableOmemoByDefault,
                onChanged: (value) {
                  context.read<PreferencesBloc>().add(
                        PreferencesChangedEvent(
                          state.copyWith(enableOmemoByDefault: value),
                        ),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
