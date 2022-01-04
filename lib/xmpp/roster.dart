import "package:moxxyv2/models/roster.dart";

class RosterRequestResult {
  List<RosterItem> items;
  String? ver;

  RosterRequestResult({ required this.items, this.ver });
}
