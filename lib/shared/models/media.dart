import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';
part 'media.g.dart';

@freezed
class SharedMedium with _$SharedMedium {
  factory SharedMedium(
    int id,
    String path,
    int timestamp,
    { String? mime, }
  ) = _SharedMedia;

  const SharedMedium._();
  
  // JSON
  factory SharedMedium.fromJson(Map<String, dynamic> json) => _$SharedMediumFromJson(json);

  factory SharedMedium.fromDatabaseJson(Map<String, dynamic> json) {
    return SharedMedium.fromJson(json);
  }

  Map<String, dynamic> toDatabaseJson() {
    return toJson()
      ..remove('id');
  }
}
