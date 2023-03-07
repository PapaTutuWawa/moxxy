import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/devices_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

class NewDeviceBubble extends StatelessWidget {
  const NewDeviceBubble({
    required this.data,
    required this.title,
    super.key,
  });
  final Map<String, dynamic> data;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Material(
          color: bubbleColorNewDevice,
          child: InkWell(
            onTap: () {
              context.read<DevicesBloc>().add(
                    DevicesRequestedEvent(data['jid']! as String),
                  );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: Text(
                t.pages.conversation.newDeviceMessage(title: title),
                style: const TextStyle(
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
