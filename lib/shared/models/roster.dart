import "package:equatable/equatable.dart";

// TODO: Convert to freezed
class RosterItem extends Equatable {
  final String avatarUrl;
  final String jid;
  final String title;
  final String subscription;
  final List<String> groups;
  final int id;

  const RosterItem({ required this.avatarUrl, required this.jid, required this.title, required this.subscription, required this.groups, required this.id });

  RosterItem.fromJson(Map<String, dynamic> json)
  : avatarUrl = json["avatarUrl"],
    jid = json["jid"],
    title = json["title"],
    subscription = json["subscription"],
    groups = List<String>.from(json["groups"]!),
    id = json["id"];

  Map<String, dynamic> toJson() => {
    "avatarUrl": avatarUrl,
    "jid": jid,
    "title": title,
    "subscription": subscription,
    "groups": groups,
    "id": id
  };
  
  @override
  bool get stringify => true;

  @override
  List<Object> get props => [ avatarUrl, jid, title, subscription, id, groups ];
}
