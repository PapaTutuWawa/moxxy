import 'package:moxxyv2/shared/cache.dart';

import 'package:test/test.dart';

void main() {
  test('Test the LRU cache', () {
    final cache = LRUCache<String, int>(2)
      ..cache('a', 1)
      ..cache('b', 2);

    expect(cache.inCache('a'), true);
    expect(cache.inCache('b'), true);

    cache.cache('c', 3);
    expect(cache.inCache('a'), false);
    expect(cache.inCache('b'), true);
    expect(cache.inCache('c'), true);

    cache.cache('c', 4);
    expect(cache.inCache('b'), true);
    expect(cache.inCache('c'), true);
    expect(cache.getValue('c'), 4);
  });
}
