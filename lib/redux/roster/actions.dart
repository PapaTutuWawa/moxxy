class AddRosterItemAction {
  final String avatarUrl;
  final String jid;
  final String title;
  final bool triggeredByDatabase;

  AddRosterItemAction({ required this.avatarUrl, required this.jid, required this.title, this.triggeredByDatabase = false });
}
