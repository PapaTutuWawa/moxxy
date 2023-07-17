import 'package:freezed_annotation/freezed_annotation.dart';

part 'groupchat.freezed.dart';
part 'groupchat.g.dart';

@freezed
class GroupchatDetails with _$GroupchatDetails {
  factory GroupchatDetails(
    String jid,
    String nick,
  ) = _GroupchatDetails;

  const GroupchatDetails._();

  /// JSON
  factory GroupchatDetails.fromJson(Map<String, dynamic> json) =>
      _$GroupchatDetailsFromJson(json);

  factory GroupchatDetails.fromDatabaseJson(
    Map<String, dynamic> json,
  ) {
    return GroupchatDetails.fromJson(json);
  }
}
