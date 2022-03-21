import "package:moxxyv2/shared/eventhandler.dart";

import "package:test/test.dart";

class FooEvent extends BaseEvent {}
class BarEvent extends BaseEvent {}

void main() {
  test("Test simple callbacks", () {
      int handled = 0;
      final handler = EventHandler();
      handler.addMatcher(EventTypeMatcher<FooEvent>((event) => handled++));
      handler.run(FooEvent());
      handler.run(BarEvent());

      expect(handled, 1);
  });
}
