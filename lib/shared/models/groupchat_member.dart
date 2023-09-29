import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/helpers.dart';

part 'groupchat_member.freezed.dart';
part 'groupchat_member.g.dart';

// TODO: Move somewhere else so that we can reuse it.
class BooleanTypeConverter extends JsonConverter<bool, int> {
  const BooleanTypeConverter();

  @override
  bool fromJson(int json) {
    return intToBool(json);
  }

  @override
  int toJson(bool object) {
    return boolToInt(object);
  }
}

class RoleTypeConverter extends JsonConverter<Role, String> {
  const RoleTypeConverter();

  @override
  Role fromJson(String json) {
    return Role.fromString(json);
  }

  @override
  String toJson(Role object) {
    return object.value;
  }
}

class AffiliationTypeConverter extends JsonConverter<Affiliation, String> {
  const AffiliationTypeConverter();

  @override
  Affiliation fromJson(String json) {
    return Affiliation.fromString(json);
  }

  @override
  String toJson(Affiliation object) {
    return object.value;
  }
}

@freezed
class GroupchatMember with _$GroupchatMember {
  factory GroupchatMember(
    String accountJid,
    String roomJid,
    String nick,
    @RoleTypeConverter() Role role,
    @AffiliationTypeConverter() Affiliation affiliation,
    String? avatarPath,
    String? avatarHash,
    String? realJid,
    @BooleanTypeConverter() bool isSelf,
  ) = _GroupchatMember;

  /// JSON
  factory GroupchatMember.fromJson(Map<String, dynamic> json) =>
      _$GroupchatMemberFromJson(json);
}
