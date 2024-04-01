import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/state/preferences.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/settings/privacy/redirect_dialog.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';

class RedirectSettingsTile extends StatelessWidget {
  const RedirectSettingsTile(
    this.serviceName,
    this.exampleProxy,
    this.getProxy,
    this.setProxy,
    this.getEnabled,
    this.setEnabled, {
    super.key,
  });
  final String serviceName;
  final String exampleProxy;
  final String Function(PreferencesState state) getProxy;
  final PreferencesState Function(PreferencesState state, String value)
      setProxy;
  final bool Function(PreferencesState state) getEnabled;
  final PreferencesState Function(PreferencesState state, bool value)
      setEnabled;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) => SettingsRow(
        title:
            t.pages.settings.privacy.redirectsTitle(serviceName: serviceName),
        description: t.pages.settings.privacy.redirectText(
          serviceName: serviceName,
          exampleProxy: exampleProxy,
        ),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext context) => RedirectDialog(
              (value) {
                context.read<PreferencesCubit>().change(
                      setProxy(state, value),
                    );
              },
              serviceName,
              getProxy(state),
            ),
          );
        },
        suffix: Switch(
          value: getEnabled(state),
          onChanged: (value) {
            if (getProxy(state).isEmpty) {
              showInfoDialog(
                t.pages.settings.privacy
                    .cannotEnableRedirect(serviceName: serviceName),
                t.pages.settings.privacy.cannotEnableRedirectSubtext,
                context,
              );
              return;
            }

            context.read<PreferencesCubit>().change(setEnabled(state, value));
          },
        ),
      ),
    );
  }
}
