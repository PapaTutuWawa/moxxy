import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';

/// Sends a block command to the service to block [jid].
void blockJid(String jid, BuildContext context) {
  showConfirmationDialog(
    'Block $jid?',
    "Are you sure you want to block $jid? You won't receive messages from them until you unblock them.",
    context,
    () {
      context.read<ConversationBloc>().add(JidBlockedEvent(jid));
      Navigator.of(context).pop();
    }
  );
}
