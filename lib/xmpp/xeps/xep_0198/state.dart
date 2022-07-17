import 'package:freezed_annotation/freezed_annotation.dart';

part 'state.freezed.dart';
part 'state.g.dart';

@freezed
class StreamManagementState with _$StreamManagementState {
  factory StreamManagementState(
    int c2s,
    int s2c,
    {
      String? streamResumptionLocation,
      String? streamResumptionId,
    }
  ) = _StreamManagementState;

  // JSON
  factory StreamManagementState.fromJson(Map<String, dynamic> json) => _$StreamManagementStateFromJson(json);
}
