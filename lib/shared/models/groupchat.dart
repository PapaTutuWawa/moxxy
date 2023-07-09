import 'package:freezed_annotation/freezed_annotation.dart';

part 'groupchat.freezed.dart';
part 'groupchat.g.dart';

@freezed
class GroupchatDetails with _$GroupchatDetails {
  factory GroupchatDetails(
    String nick,
  ) = _GroupchatDetails;

  /// JSON
  factory GroupchatDetails.fromJson(Map<String, dynamic> json) =>
      _$GroupchatDetailsFromJson(json);
}
