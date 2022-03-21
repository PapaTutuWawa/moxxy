import "package:moxxyv2/shared/awaitabledatasender.dart";

import "package:test/test.dart";

class TestDataType implements JsonImplementation {
  final String data;

  TestDataType(this.data);

  Map<String, dynamic> toJson() => {
    "data": data
  };

  factory TestDataType.fromJson(Map<String, dynamic> json) => TestDataType(
    json["data"]!
  );
}

class FakeAwaitableDataSender<
  S extends JsonImplementation,
  R extends JsonImplementation
> extends AwaitableDataSender<S, R> {
  final void Function()? onAddFunc;

  FakeAwaitableDataSender({ this.onAddFunc }) : super();

  @override
  Future<void> sendDataImpl(DataWrapper data) async {}

  @override
  void onAdd() {
    onAddFunc?.call();
  }
}

void main() {
  test("Sending an event without awaiting it", () async {
      final handler = FakeAwaitableDataSender<TestDataType, TestDataType>();
      final result = await handler.sendData(TestDataType("hallo"), awaitable: false);

      expect(result, null);
      expect(handler.getAwaitables().length, 0);
  });

  test("Sending an event without awaiting it", () async {
      final handler = FakeAwaitableDataSender<TestDataType, TestDataType>();
      final id = "abc123";
      final result = handler.sendData(TestDataType("hallo"), awaitable: true, id: id);
      await handler.onData(DataWrapper(id, TestDataType("welt")));

      expect((await result)!.data, "welt");
      expect(handler.getAwaitables().length, 0);
  });

  test("Queue multiple data packets and resolve in reverse order", () async {
      int i = 0;
      final handler = FakeAwaitableDataSender<TestDataType, TestDataType>(
        onAddFunc: () {
          i++;
          expect(i <= 2, true); 
        }
      );
      final a = handler.sendData(TestDataType("1"), id: "1");
      final b = handler.sendData(TestDataType("2"), id: "2");

      await handler.onData(DataWrapper("2", TestDataType("4")));
      await handler.onData(DataWrapper("1", TestDataType("1")));

      expect((await a)!.data, "1");
      expect((await b)!.data, "4");
  });
}
