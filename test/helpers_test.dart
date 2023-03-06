import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';

void main() {
  group('padInt', () {
    test('0 should be padded to 00', () {
      expect(padInt(0), '00');
    });
    test('5 should be padded to 05', () {
      expect(padInt(5), '05');
    });
    test('23 should not be padded', () {
      expect(padInt(25), '25');
    });
    test('99 should not be padded', () {
      expect(padInt(99), '99');
    });
  });

  group('formatConversationTimestamp', () {
    test('Just now', () {
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
        ),
        'Just now',
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 18, 50).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
        ),
        isNot('Just now'),
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
        ),
        'Just now',
      );
    });
    test('nh', () {
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 13, 20).millisecondsSinceEpoch,
        ),
        '1h',
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 13, 19, 40).millisecondsSinceEpoch,
        ),
        '1h',
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 27, 11, 19, 40).millisecondsSinceEpoch,
        ),
        '23h',
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 27, 12, 19, 40).millisecondsSinceEpoch,
        ),
        isNot('24h'),
      );
    });
    test('yesterday', () {
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 27, 11, 20).millisecondsSinceEpoch,
        ),
        isNot('Yesterday'),
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 28, 11, 19, 40).millisecondsSinceEpoch,
        ),
        isNot('Yesterday'),
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 19, 40).millisecondsSinceEpoch,
          DateTime(2021, 12, 28, 12, 19, 40).millisecondsSinceEpoch,
        ),
        isNot('Yesterday'),
      );
    });
    test('date', () {
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 27, 12, 20).millisecondsSinceEpoch,
        ),
        '26.12.',
      );
      expect(
        formatConversationTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2022, 12, 27, 12, 20).millisecondsSinceEpoch,
        ),
        '26.12.2021',
      );
    });
  });

  group('formatMessageTimestamp', () {
    test('Just noww', () {
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
        ),
        'Just now',
      );
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2022, 12, 26, 12, 21).millisecondsSinceEpoch,
        ),
        isNot('Just now'),
      );
    });
    test('nmin ago', () {
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 21).millisecondsSinceEpoch,
        ),
        '1min ago',
      );
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 28).millisecondsSinceEpoch,
        ),
        '8min ago',
      );
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 35).millisecondsSinceEpoch,
        ),
        isNot('15min ago'),
      );
    });
    test('hh:mm', () {
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 26, 12, 20).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 35).millisecondsSinceEpoch,
        ),
        '12:20',
      );
      expect(
        formatMessageTimestamp(
          DateTime(2021, 12, 20, 15, 27).millisecondsSinceEpoch,
          DateTime(2021, 12, 26, 12, 35).millisecondsSinceEpoch,
        ),
        '15:27',
      );
    });
  });

  group('validateJid', () {
    test('Valid JIDs', () {
      expect(validateJid('polynomdivision@someserver.example'),
          JidFormatError.none);
      expect(validateJid('a@b.c'), JidFormatError.none);
      expect(validateJid('a@192.168.178.1'), JidFormatError.none);
      expect(validateJid('a@local'), JidFormatError.none);
    });
    test('Invalid JIDs', () {
      expect(validateJid('polynomdivision'), JidFormatError.noSeparator);
      expect(validateJid('a@'), JidFormatError.noDomain);
      expect(validateJid(''), JidFormatError.empty);
      expect(validateJid('a@local@host'), JidFormatError.tooManySeparators);
      expect(validateJid('@local'), JidFormatError.noLocalpart);
    });
  });

  group('filenameWithSuffix', () {
    test('Test simple filenames', () {
      expect(filenameWithSuffix('test.jpg', '(1)'), 'test(1).jpg');
      expect(filenameWithSuffix('test.welt.jpg', '(1)'), 'test.welt(1).jpg');
      expect(filenameWithSuffix('file-without-extension', '(1)'),
          'file-without-extension(1)');
    });

    test('Test edge cases', () {
      expect(filenameWithSuffix('test.png', ''), 'test.png');
    });
  });

  test('formatDateBubble', () {
    expect(
      formatDateBubble(
        DateTime(2022, 7, 31, 7, 26),
        DateTime(2022, 7, 31, 11, 15),
      ),
      'Today',
    );

    expect(
      formatDateBubble(
        DateTime(2022, 7, 30, 22, 39),
        DateTime(2022, 7, 31, 11, 15),
      ),
      'Yesterday',
    );

    expect(
      formatDateBubble(
        DateTime(2022, 7, 29, 7, 25),
        DateTime(2022, 7, 31, 11, 15),
      ),
      'Fri., 29. July',
    );

    expect(
      formatDateBubble(
        DateTime(2019, 7, 29, 7, 25),
        DateTime(2022, 7, 31, 11, 15),
      ),
      '29. July 2019',
    );
  });

  test('clampedListPrepend', () {
    expect(
      clampedListPrepend([1, 2, 3], 4, 4),
      [4, 1, 2, 3],
    );
    expect(
      clampedListPrepend([1, 2, 3, 4], 5, 4),
      [5, 1, 2, 3],
    );
    expect(
      clampedListPrepend([1, 2, 3, 4, 5, 6], 7, 4),
      [7, 1, 2, 3],
    );
  });

  test('clampedListPrependAll', () {
    expect(
      clampedListPrependAll([1, 2, 3], [4, 5], 5),
      [4, 5, 1, 2, 3],
    );
    expect(
      clampedListPrependAll([1, 2, 3], [4, 5], 4),
      [4, 5, 1, 2],
    );
    expect(
      clampedListPrependAll([1, 2, 3, 4, 5], [6, 7], 4),
      [6, 7, 1, 2],
    );
  });
}
