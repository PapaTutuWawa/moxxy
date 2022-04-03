import "package:freezed_annotation/freezed_annotation.dart";

part "media.freezed.dart";
part "media.g.dart";

@freezed
class SharedMedium with _$SharedMedium {
  factory SharedMedium(
    int id,
    String path,
    { String? mime }
  ) = _SharedMedia;

  // JSON
  factory SharedMedium.fromJson(Map<String, dynamic> json) => _$SharedMediumFromJson(json);
}
