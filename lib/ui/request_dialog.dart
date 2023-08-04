import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/request_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestDialog extends StatelessWidget {
  const RequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(textfieldRadiusRegular),
      ),
      child: BlocConsumer<RequestBloc, RequestBlocState>(
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
                      onPressed: () {
                        switch (request) {
                          case Request.notifications:
                            Permission.notification.request();
                            break;
                          case Request.batterySavingExcemption:
                            // TODO
                            break;
                        }

                        context.read<RequestBloc>().add(NextRequestEvent());
                      },
                      child: Text(t.permissions.allow),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<RequestBloc>().add(NextRequestEvent());
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
