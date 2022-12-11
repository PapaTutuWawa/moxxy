import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';

class RebuildOnContactIntegrationChange extends StatelessWidget {
  const RebuildOnContactIntegrationChange({
    required this.builder,
    super.key,
  });
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesBloc, PreferencesState>(
      buildWhen: (prev, next) => prev.enableContactIntegration != next.enableContactIntegration,
      builder: (_, __) => builder(),
    );
  }
}
