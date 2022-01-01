import "package:isar/isar.dart";
import "package:moxxyv2/isar.g.dart";

@Collection()
@Name("Message")
class DBMessage {
  int? id;

  @Index(caseSensitive: false)
  late String from;

  late int timestamp;

  late String body;

  late bool sent;
}
