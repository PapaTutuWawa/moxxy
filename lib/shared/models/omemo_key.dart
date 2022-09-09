import 'package:freezed_annotation/freezed_annotation.dart';

part 'omemo_key.freezed.dart';
part 'omemo_key.g.dart';

/// This model is just for communication between UI and the backend.
@freezed
class OmemoKey with _$OmemoKey {
  factory OmemoKey(
    String fingerprint,
    bool verified,
  ) = _OmemoKey;

  /// JSON
  factory OmemoKey.fromJson(Map<String, dynamic> json) => _$OmemoKeyFromJson(json);
}
