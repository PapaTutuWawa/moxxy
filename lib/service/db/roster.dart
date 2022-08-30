import 'package:isar/isar.dart';

part 'roster.g.dart';

@Collection()
@Name('RosterItem')
class DBRosterItem {
  Id? id;

  late String jid;

  late String title;

  late String avatarUrl;
  late String avatarHash;

  late List<String> groups;

  late String subscription;

  late String ask;
}
