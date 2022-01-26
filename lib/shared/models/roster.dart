import "package:equatable/equatable.dart";

class RosterItem extends Equatable {
  final String avatarUrl;
  final String jid;
  final String title;
  final int id;

  const RosterItem({ required this.avatarUrl, required this.jid, required this.title, required this.id });

  RosterItem.fromJson(Map<String, dynamic> json)
  : avatarUrl = json["avatarUrl"],
  jid = json["jid"],
  title = json["title"],
  id = json["id"];

  Map<String, dynamic> toJson() => {
    "avatarUrl": avatarUrl,
    "jid": jid,
    "title": title,
    "id": id
  };
  
  @override
  bool get stringify => true;

  @override
  List<Object> get props => [ avatarUrl, jid, title, id ];
}
