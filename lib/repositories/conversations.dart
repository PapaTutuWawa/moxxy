import "dart:collection";

import "package:moxxyv2/models/conversation.dart";

class ConversationRepository {
  HashMap<String, Conversation> _conversations = HashMap.from({
    "houshou.marine@hololive.tv": Conversation(
      title: "Houshou Marine",
      lastMessageBody: "UwU",
      avatarUrl: "https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347",
      jid: "houshou.marine@hololive.tv"
    )
});

  ConversationRepository();

  bool hasJid(String jid) => this._conversations.containsKey(jid);
  
  Conversation? getConversation(String jid) => this._conversations[jid];
  void setConversation(Conversation conversation) {
    this._conversations[conversation.jid] = conversation;
  }
}
