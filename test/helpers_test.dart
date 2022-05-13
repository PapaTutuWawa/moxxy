import 'package:test/test.dart';

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

import "./helpers/xml.dart";

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

  group("firstWhereOrNull", () {
      test("[] should not contain 1", () {
          expect(firstWhereOrNull<int>([], (int element) => element == 1), null);
      });
      test("[1, 2, 3] should contain 2", () {
          expect(firstWhereOrNull([ 1, 2, 3 ], (int element) => element == 2), 2);
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

  group("validateJid", () {
      test("Valid JIDs", () {
          expect(validateJid("polynomdivision@someserver.example"), JidFormatError.none);
          expect(validateJid("a@b.c"), JidFormatError.none);
          expect(validateJid("a@192.168.178.1"), JidFormatError.none);
          expect(validateJid("a@local"), JidFormatError.none);
      });
      test("Invalid JIDs", () {
          expect(validateJid("polynomdivision"), JidFormatError.noSeparator);
          expect(validateJid("a@"), JidFormatError.noDomain);
          expect(validateJid(""), JidFormatError.empty);
          expect(validateJid("a@local@host"), JidFormatError.tooManySeparators);
          expect(validateJid("@local"), JidFormatError.noLocalpart);
      });
  });

  group("compareXMLNodes", () {
      test("Compare simple nodes", () {
          expect(
            compareXMLNodes(
              XMLNode.fromString("<a xmlns=\"a:b:c\"></a>"),
              XMLNode.fromString("<a xmlns=\"a:b:c\" />")
            ),
            true
          );

          expect(
            compareXMLNodes(
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child count=\"1\"></child></a>"),
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child count=\"1\" /></a>")
            ),
            true
          );

          expect(
            compareXMLNodes(
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child count=\"1\" /></a>"),
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child count=\"2\" /></a>")
            ),
            false
          );

          expect(
            compareXMLNodes(
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child>some text</child></a>"),
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child>some other text</child></a>")
            ),
            false
          );

          expect(
            compareXMLNodes(
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child>some text</child></a>"),
              XMLNode.fromString("<a xmlns=\"a:b:c\"><child>some text</child></a>")
            ),
            true
          );
      });
      test("Compare nodes and ignore the id attribute", () {
          expect(
            compareXMLNodes(
              XMLNode.fromString("<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn' id='3c080624-949f-4c9f-9646-2cc6088d820b'><show>chat</show><c xmlns='http://jabber.org/protocol/caps' ver='eTczQOjOi9iroU5zVG7uBBTD4eQ=' node='http://moxxy.im' hash='sha-1' /></presence>"),
              XMLNode.fromString("<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn'><show>chat</show><c xmlns='http://jabber.org/protocol/caps' hash='sha-1' node='http://moxxy.im' ver='eTczQOjOi9iroU5zVG7uBBTD4eQ=' /></presence>"),
              ignoreId: false
            ),
            false
          );
          expect(
            compareXMLNodes(
              XMLNode.fromString("<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn' id='3c080624-949f-4c9f-9646-2cc6088d820b'><show>chat</show><c xmlns='http://jabber.org/protocol/caps' ver='eTczQOjOi9iroU5zVG7uBBTD4eQ=' node='http://moxxy.im' hash='sha-1' /></presence>"),
              XMLNode.fromString("<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn'><show>chat</show><c xmlns='http://jabber.org/protocol/caps' hash='sha-1' node='http://moxxy.im' ver='eTczQOjOi9iroU5zVG7uBBTD4eQ=' /></presence>"),
              ignoreId: true
            ),
            true
          );
      });
  });

  group("firstNotNull", () {
      test("Test simple lists", () {
          expect(firstNotNull<int?>([null, null]), null);
          expect(firstNotNull([1, null]), 1);
          expect(firstNotNull([null, null, 2]), 2);
      });
  });
}
