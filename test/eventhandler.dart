import 'package:moxxyv2/shared/eventhandler.dart';

import 'package:test/test.dart';

class FooEvent {}

class BarEvent {}

void main() {
  test('Test simple callbacks', () {
    var handled = 0;
    EventHandler()
      ..addMatchers([
        EventTypeMatcher<FooEvent>((event, {extra}) async {
          handled++;
        }),
      ])
      ..run(FooEvent())
      ..run(BarEvent());

    expect(handled, 1);
  });
}
