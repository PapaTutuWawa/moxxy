import "package:isar/isar.dart";

@Collection()
@Name("RosterItem")
class DBRosterItem {
  int? id;

  late String jid;

  late String title;

  late String avatarUrl;
}
