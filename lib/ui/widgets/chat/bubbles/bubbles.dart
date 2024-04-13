import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/state/devices.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/omemo.dart';

Widget bubbleFromPseudoMessageType(BuildContext context, Message message) {
  assert(
    message.pseudoMessageType != null,
    'Message must have non-null pseudoMessageType',
  );

  switch (message.pseudoMessageType!) {
    case PseudoMessageType.changedDevice:
      final replacedAmount =
          (message.pseudoMessageData?['ratchetsReplaced'] as int?) ?? 1;
      return OmemoBubble(
        text: t.pages.conversation.replacedDeviceMessage(n: replacedAmount),
        onTap: () {
          context.read<DevicesCubit>().request(
                message.conversationJid,
              );
        },
      );
    case PseudoMessageType.newDevice:
      final addedAmount =
          (message.pseudoMessageData?['ratchetsAdded'] as int?) ?? 1;
      return OmemoBubble(
        text: t.pages.conversation.newDeviceMessage(n: addedAmount),
        onTap: () {
          context.read<DevicesCubit>().request(
                message.conversationJid,
              );
        },
      );
  }
}
