import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class NewConversationPage extends StatelessWidget {
  const NewConversationPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const NewConversationPage(),
        settings: const RouteSettings(
          name: newConversationRoute,
        ),
      );

  Widget _renderIconEntry(IconData icon, String text, void Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AvatarWrapper(
              radius: 35,
              altIcon: icon,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxTextWidth = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.newconversation.title),
      body: BlocBuilder<NewConversationBloc, NewConversationState>(
        builder: (BuildContext context, NewConversationState state) =>
            ListView.builder(
          itemCount: state.roster.length + 1,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _renderIconEntry(
                  Icons.person_add,
                  t.pages.newconversation.addContact,
                  () => Navigator.pushNamed(context, addContactRoute),
                );
              default:
                final item = state.roster[index - 1];
                return Dismissible(
                  key: ValueKey('roster;${item.jid}'),
                  direction: item.pseudoRosterItem
                      ? DismissDirection.none
                      : DismissDirection.horizontal,
                  onDismissed: (_) => context.read<NewConversationBloc>().add(
                        NewConversationRosterItemRemovedEvent(item.jid),
                      ),
                  background: ColoredBox(
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          Icon(Icons.delete),
                          Spacer(),
                          Icon(Icons.delete)
                        ],
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => context.read<NewConversationBloc>().add(
                          NewConversationAddedEvent(
                            item.jid,
                            item.title,
                            item.avatarUrl,
                            ConversationType.chat,
                          ),
                        ),
                    child: ConversationsListRow(
                      maxTextWidth,
                      Conversation(
                        item.title,
                        Message(
                          '',
                          item.jid,
                          0,
                          '',
                          0,
                          '',
                          false,
                          false,
                          false,
                        ),
                        item.avatarUrl,
                        item.jid,
                        0,
                        ConversationType.chat,
                        0,
                        true,
                        true,
                        '',
                        false,
                        false,
                        ChatState.gone,
                        contactId: item.contactId,
                        contactAvatarPath: item.contactAvatarPath,
                        contactDisplayName: item.contactDisplayName,
                      ),
                      false,
                      showTimestamp: false,
                      titleSuffixIcon:
                          item.pseudoRosterItem ? Icons.smartphone : null,
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
