import "dart:collection";

import "package:equatable/equatable.dart";

class RosterItem extends Equatable {
  final String avatarUrl;
  final String jid;
  final String title;
  final int id;

  RosterItem({ required this.avatarUrl, required this.jid, required this.title, required this.id });

  RosterItem.fromJson(Map<String, dynamic> json)
  : avatarUrl = json["avatarUrl"],
  jid = json["jid"],
  title = json["title"],
  id = json["id"];

  Map<String, dynamic> toJson() => {
    "avatarUrl": this.avatarUrl,
    "jid": this.jid,
    "title": this.title,
    "id": this.id
  };
  
  @override
  bool get stringify => true;

  @override
  List<Object> get props => [ avatarUrl, jid, title, id ];
}
