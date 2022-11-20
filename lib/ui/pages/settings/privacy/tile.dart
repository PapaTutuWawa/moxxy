import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/settings/privacy/redirect_dialog.dart';
import 'package:settings_ui/settings_ui.dart';

class RedirectSettingsTile extends AbstractSettingsTile {
  const RedirectSettingsTile(
    this.serviceName,
    this.exampleProxy,
    this.getProxy,
    this.setProxy,
    this.getEnabled,
    this.setEnabled,
    { super.key, }
  );
  final String serviceName;
  final String exampleProxy;
  final String Function(PreferencesState state) getProxy;
  final PreferencesState Function(PreferencesState state, String value) setProxy;
  final bool Function(PreferencesState state) getEnabled;
  final PreferencesState Function(PreferencesState state, bool value) setEnabled;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      builder: (context, state) => SettingsTile(
        title: Text(t.pages.settings.privacy.redirectsTitle(serviceName: serviceName)),
        description: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.pages.settings.privacy.redirectText(
                  serviceName: serviceName,
                  exampleProxy: exampleProxy,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.pages.settings.privacy.currentlySelected(proxy: getProxy(state)),
              ),
            ),
          ],
        ),
        onPressed: (context) {
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) => RedirectDialog(
              (value) {
                context.read<PreferencesBloc>().add(PreferencesChangedEvent(setProxy(state, value)));
              },
              serviceName,
              getProxy(state),
            ),
          );
        },
        trailing: Switch(
          value: getEnabled(state),
          onChanged: (value) {
            if (getProxy(state).isEmpty) {
              showInfoDialog(
                t.pages.settings.privacy.cannotEnableRedirect(serviceName: serviceName),
                t.pages.settings.privacy.cannotEnableRedirectSubtext,
                context,
              );
              return;
            }

            context.read<PreferencesBloc>().add(PreferencesChangedEvent(setEnabled(state, value)));
          },
        ),
      ),
    );
  }
}
