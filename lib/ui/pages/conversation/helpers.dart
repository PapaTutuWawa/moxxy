import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/helpers.dart';

/// Sends a block command to the service to block [jid].
Future<void> blockJid(String jid, BuildContext context) async {
  final result = await showConfirmationDialog(
    'Block $jid?',
    "Are you sure you want to block $jid? You won't receive messages from them until you unblock them.",
    context,
  );

  if (result) {
    // ignore: use_build_context_synchronously
    context.read<ConversationBloc>().add(JidBlockedEvent(jid));

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }
}
