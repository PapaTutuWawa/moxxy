import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';

/// Builds the widget that will be put into the modal BottomSheet where the user can, for
/// example disable sharing their online status with the contact.
Widget buildConversationOptionsModal() {
  return BlocBuilder<ProfileBloc, ProfileState>(
    buildWhen: (prev, next) => prev.conversation?.subscription != next.conversation?.subscription,
    builder: (context, state) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Contact Options',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),

        Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const Text('Share online status'),
                Switch(
                  value: state.conversation!.subscription == 'to' ||
                         state.conversation!.subscription == 'both',
                  onChanged: (value) => GetIt.I.get<ProfileBloc>().add(
                    SetSubscriptionStateEvent(
                      state.conversation!.jid,
                      value,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class ConversationProfileHeader extends StatelessWidget {

  const ConversationProfileHeader(this.conversation, { Key? key }) : super(key: key);
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'conversation_profile_picture',
          child: Material(
            child: AvatarWrapper(
              radius: 110,
              avatarUrl: conversation.avatarUrl,
              altText: conversation.title,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            conversation.title,
            style: const TextStyle(
              fontSize: 30,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            conversation.jid,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
