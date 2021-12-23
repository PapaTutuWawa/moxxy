import "dart:collection";

import "package:moxxyv2/models/conversation.dart";

class ConversationRepository {
  HashMap<String, Conversation> _conversations = HashMap.from({
      // TODO: Remove
      "houshou.marine@hololive.tv": Conversation(
        title: "Houshou Marine",
        lastMessageBody: "UwU",
        avatarUrl: "https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347",
        jid: "houshou.marine@hololive.tv"
      ),
      "nakiri.ayame@hololive.tv": Conversation(
        title: "Nakiri Ayame",
        lastMessageBody: "Yodayo~",
        avatarUrl: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.pinimg.com%2Foriginals%2F2a%2F77%2F0a%2F2a770a77b0d873331583dfb88b05829f.jpg&f=1&nofb=1",
        jid: "nakiri.ayame@hololive.tv"
      )
  });

  ConversationRepository();

  bool hasJid(String jid) => this._conversations.containsKey(jid);
  
  Conversation? getConversation(String jid) => this._conversations[jid];
  void setConversation(Conversation conversation) {
    this._conversations[conversation.jid] = conversation;
  }

  List<Conversation> getAllConversations() {
    return this._conversations.values.toList();
  }
}
