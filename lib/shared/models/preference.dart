import 'package:freezed_annotation/freezed_annotation.dart';

part 'preference.freezed.dart';
part 'preference.g.dart';

@freezed
class Preference with _$Preference {
  factory Preference(
    String key,
    int type,
    String? value,
  ) = _Preference;

  const Preference._();

  /// JSON
  factory Preference.fromJson(Map<String, dynamic> json) =>
      _$PreferenceFromJson(json);

  factory Preference.fromDatabaseJson(Map<String, dynamic> json) {
    return Preference.fromJson(json);
  }

  Map<String, dynamic> toDatabaseJson() {
    return toJson();
  }
}
