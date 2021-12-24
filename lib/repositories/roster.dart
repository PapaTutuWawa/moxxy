import "dart:collection";

import "package:moxxyv2/models/roster.dart";

class RosterRepository {
  HashMap<String, RosterItem> _rosterItems = HashMap.from({
      // TODO: Remove
      "houshou.marine@hololive.tv": RosterItem(
        title: "Houshou Marine",
        avatarUrl: "https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347",
        jid: "houshou.marine@hololive.tv",
      ),
      "nakiri.ayame@hololive.tv": RosterItem(
        title: "Nakiri Ayame",
        avatarUrl: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.pinimg.com%2Foriginals%2F2a%2F77%2F0a%2F2a770a77b0d873331583dfb88b05829f.jpg&f=1&nofb=1",
        jid: "nakiri.ayame@hololive.tv",
      ),
      "momosuzu.nene@hololive.tv": RosterItem(
        title: "Momosuzu Nene",
        avatarUrl: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fstatic.miraheze.org%2Fhololivewiki%2Fthumb%2F3%2F36%2FMomosuzu_Nene_-_Portrait_01-1.png%2F580px-Momosuzu_Nene_-_Portrait_01-1.png&f=1&nofb=1",
        jid: "momosuzu.nene@hololive.tv",
      )
  });

  RosterRepository();

  bool hasJid(String jid) => this._rosterItems.containsKey(jid);
  
  RosterItem? getRosterItem(String jid) => this._rosterItems[jid];
  void setRosterItem(RosterItem item) {
    this._rosterItems[item.jid] = item;
  }

  List<RosterItem> getAllRosterItems() {
    return this._rosterItems.values.toList();
  }
}
