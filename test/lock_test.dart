import 'package:moxxyv2/shared/helpers.dart';
import 'package:synchronized/synchronized.dart';
import 'package:test/test.dart';

void main() {
  test('Test having an exception in the critical section', () async {
    final lock = Lock();

    var caught = false;
    try {
      await lock.safeSynchronized(() async {
        throw Exception();
      });
    } catch (_) {
      caught = true;
    }

    expect(caught, true);
  });
}
