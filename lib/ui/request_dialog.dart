import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/state/request.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestDialog extends StatelessWidget {
  const RequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: BlocConsumer<RequestCubit, RequestState>(
        listener: (_, state) {
          // Automatically dismiss the dialog when we're done
          if (!state.shouldShow) {
            Navigator.of(context).pop();
          }
        },
        buildWhen: (_, next) => next.shouldShow,
        builder: (context, state) {
          final request = state.requests[state.currentIndex];
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(request.reason),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        switch (request) {
                          case Request.notifications:
                            await Permission.notification.request();
                          case Request.batterySavingExcemption:
                            await MoxxyPlatformApi()
                                .openBatteryOptimisationSettings();
                        }

                        GetIt.I.get<RequestCubit>().nextRequest();
                      },
                      child: Text(t.permissions.allow),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<RequestCubit>().nextRequest();
                      },
                      child: Text(t.permissions.skip),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
