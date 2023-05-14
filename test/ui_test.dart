import 'package:moxxyv2/shared/models/reaction_group.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/list.dart';
import 'package:test/test.dart';

void main() {
  group('ensureReactionGroupOrder', () {
    test('Own JID not included', () {
      final result = ensureReactionGroupOrder(
        [
          ReactionGroup('a', ['a', 'b', 'c']),
          ReactionGroup('b', ['a', 'b']),
          ReactionGroup('c', ['a', 'c', 'd']),
        ],
        'moxxy',
      );

      expect(result.length, 4);
      expect(result[0].jid, 'moxxy');
      expect(result[0].emojis, <String>[]);
      expect(result[1].jid, 'a');
      expect(result[2].jid, 'b');
      expect(result[3].jid, 'c');
    });

    test('Own JID included in the middle', () {
      final result = ensureReactionGroupOrder(
        [
          ReactionGroup('a', ['a', 'b', 'c']),
          ReactionGroup('b', ['a', 'b']),
          ReactionGroup('moxxy', ['e']),
          ReactionGroup('c', ['a', 'c', 'd']),
        ],
        'moxxy',
      );

      expect(result.length, 4);
      expect(result[0].jid, 'moxxy');
      expect(result[1].jid, 'a');
      expect(result[2].jid, 'b');
      expect(result[3].jid, 'c');
    });

    test('Own JID included at the start', () {
      final result = ensureReactionGroupOrder(
        [
          ReactionGroup('moxxy', ['e']),
          ReactionGroup('a', ['a', 'b', 'c']),
          ReactionGroup('b', ['a', 'b']),
          ReactionGroup('c', ['a', 'c', 'd']),
        ],
        'moxxy',
      );

      expect(result.length, 4);
      expect(result[0].jid, 'moxxy');
      expect(result[1].jid, 'a');
      expect(result[2].jid, 'b');
      expect(result[3].jid, 'c');
    });

    test('Own JID included at the end', () {
      final result = ensureReactionGroupOrder(
        [
          ReactionGroup('a', ['a', 'b', 'c']),
          ReactionGroup('b', ['a', 'b']),
          ReactionGroup('c', ['a', 'c', 'd']),
          ReactionGroup('moxxy', ['e']),
        ],
        'moxxy',
      );

      expect(result.length, 4);
      expect(result[0].jid, 'moxxy');
      expect(result[1].jid, 'a');
      expect(result[2].jid, 'b');
      expect(result[3].jid, 'c');
    });
  });
}
