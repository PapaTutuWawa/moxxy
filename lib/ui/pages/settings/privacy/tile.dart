import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        title: Text('$serviceName Redirect'),
        description: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('This will redirect $serviceName links that you tap to a proxy service, e.g. $exampleProxy'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Currently selected: ${getProxy(state)}'),
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
                'Cannot enable $serviceName redirects',
                'You must first set a proxy service to redirect to. To do so, tap the field next to the switch.',
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
