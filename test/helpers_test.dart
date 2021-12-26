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

  group("listContains", () {
      test("[] should not contain 1", () {
          expect(listContains<int>([], (int element) => element == 1), false);
      });
      test("[1, 2, 3] should contain 2", () {
          expect(listContains([ 1, 2, 3 ], (int element) => element == 2), true);
      });
  });

  group("formatConversationTimestamp", () {
      test("Just now", () {
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch
          ), "Just now");
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 18, 50, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch
            ), isNot("Just now"));
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch
          ), "Just now");
      });
      test("nh", () {
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 13, 20, 0, 0, 0).millisecondsSinceEpoch
          ), "1h");
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 13, 19, 40, 0, 0).millisecondsSinceEpoch
          ), "1h");
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 27, 11, 19, 40, 0, 0).millisecondsSinceEpoch
          ), "23h");
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 27, 12, 19, 40, 0, 0).millisecondsSinceEpoch
            ), isNot("24h"));
      });
      test("yesterday", () {
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 27, 11, 20, 0, 0, 0).millisecondsSinceEpoch
            ), isNot("Yesterday"));
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 28, 11, 19, 40, 0, 0).millisecondsSinceEpoch
            ), isNot("Yesterday"));
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 19, 40, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 28, 12, 19, 40, 0, 0).millisecondsSinceEpoch
            ), isNot("Yesterday"));
      });
      test("date", () {
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 27, 12, 20, 0, 0, 0).millisecondsSinceEpoch
          ), "26.12.");
          expect(formatConversationTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2022, 12, 27, 12, 20, 0, 0, 0).millisecondsSinceEpoch
          ), "26.12.2021");
      });
  });

  group("formatMessageTimestamp", () {
      test("Just noww", () {
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch
          ), "Just now");
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2022, 12, 26, 12, 21, 0, 0, 0).millisecondsSinceEpoch
            ), isNot("Just now"));
      });
      test("nmin ago", () {
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 21, 0, 0, 0).millisecondsSinceEpoch
          ), "1min ago");
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 28, 0, 0, 0).millisecondsSinceEpoch
          ), "8min ago");
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 35, 0, 0, 0).millisecondsSinceEpoch
            ), isNot("15min ago"));
      });
      test("hh:mm", () {
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 35, 0, 0, 0).millisecondsSinceEpoch
          ), "12:20");
          expect(formatMessageTimestamp(
              DateTime(2021, 12, 20, 15, 27, 0, 0, 0).millisecondsSinceEpoch,
              DateTime(2021, 12, 26, 12, 35, 0, 0, 0).millisecondsSinceEpoch
            ), "15:27");
      });
  });
}
