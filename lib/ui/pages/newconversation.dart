import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/service/connectivity.dart';
import 'package:moxxyv2/ui/state/newconversation.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';

class NewConversationPage extends StatelessWidget {
  const NewConversationPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const NewConversationPage(),
        settings: const RouteSettings(
          name: newConversationRoute,
        ),
      );

  Widget _renderIconEntry(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusLargeSize),
        child: Material(
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 35,
                    child: Icon(icon),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.newconversation.title),
      ),
      body: BlocBuilder<NewConversationCubit, NewConversationState>(
        builder: (BuildContext context, NewConversationState state) =>
            ListView.builder(
          itemCount: state.roster.length + 2,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _renderIconEntry(
                  Icons.person_add,
                  t.pages.newconversation.startChat,
                  () {
                    if (!GetIt.I.get<UIConnectivityService>().hasConnection) {
                      Fluttertoast.showToast(
                        msg: t.errors.general.noInternet,
                      );
                      return;
                    }

                    Navigator.pushNamed(context, addContactRoute);
                  },
                );
              case 1:
                return _renderIconEntry(
                  Icons.group,
                  t.pages.newconversation.createGroupchat,
                  () {
                    if (!GetIt.I.get<UIConnectivityService>().hasConnection) {
                      Fluttertoast.showToast(
                        msg: t.errors.general.noInternet,
                      );
                      return;
                    }

                    if (kDebugMode) {
                      Navigator.pushNamed(context, addContactRoute);
                    } else {
                      showNotImplementedDialog('groupchat', context);
                    }
                  },
                );
              default:
                final item = state.roster[index - 2];
                return Dismissible(
                  key: ValueKey('roster;${item.jid}'),
                  direction: item.pseudoRosterItem
                      ? DismissDirection.none
                      : DismissDirection.horizontal,
                  onDismissed: (_) =>
                      context.read<NewConversationCubit>().remove(
                            item.jid,
                          ),
                  background: const ColoredBox(
                    color: Colors.red,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          Spacer(),
                          Icon(Icons.delete),
                        ],
                      ),
                    ),
                  ),
                  child: ConversationsListRow(
                    Conversation(
                      '',
                      item.title,
                      Message(
                        '',
                        '',
                        '',
                        item.jid,
                        0,
                        '',
                        '',
                        false,
                        false,
                        false,
                      ),
                      item.avatarPath,
                      item.avatarHash,
                      item.jid,
                      null,
                      0,
                      ConversationType.chat,
                      0,
                      true,
                      true,
                      false,
                      false,
                      ChatState.gone,
                      contactId: item.contactId,
                      contactAvatarPath: item.contactAvatarPath,
                      contactDisplayName: item.contactDisplayName,
                    ),
                    false,
                    showTimestamp: false,
                    isSelected: false,
                    onPressed: () => context.read<NewConversationCubit>().add(
                          item.jid,
                          item.title,
                          item.avatarPath,
                          ConversationType.chat,
                        ),
                    titleSuffixIcon:
                        item.pseudoRosterItem ? Icons.smartphone : null,
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
