import 'dart:math';
import 'package:random_string/random_string.dart';

/// Generate a random alpha-numeric string with a random length between 0 and 200 in
/// accordance to XEP-0420's rpad affix element.
String generateRpad() {
  final random = Random.secure();
  final length = random.nextInt(200);
  return randomAlphaNumeric(length, provider: CoreRandomProvider.from(random));
}
