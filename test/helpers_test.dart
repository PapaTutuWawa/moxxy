import 'package:test/test.dart';

import "package:moxxyv2/helpers.dart";

void main() {
  group("padInt", () {
      test("0 should be padded to 00", () {
          expect(padInt(0), "00");
      });
      test("5 should be padded to 05", () {
          expect(padInt(5), "05");
      });
      test("23 should not be padded", () {
          expect(padInt(25), "25");
      });
      test("99 should not be padded", () {
          expect(padInt(99), "99");
      });
  });
}
