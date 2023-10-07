import 'package:json_annotation/json_annotation.dart';
import 'package:moxxyv2/service/database/helpers.dart';

/// A converter for converting booleans to an integer for database usage.
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
