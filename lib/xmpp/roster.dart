class XmppRosterItem {
  final String jid;
  final String? name;
  final String subscription;

  XmppRosterItem({ required this.jid, required this.subscription, this.name });
}

class RosterRequestResult {
  List<XmppRosterItem> items;
  String? ver;

  RosterRequestResult({ required this.items, this.ver });
}
