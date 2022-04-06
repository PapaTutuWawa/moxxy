import "package:moxxyv2/shared/migrator.dart";

import "package:test/test.dart";

class Greeting {
  final String action;
  final String entity;
  final bool beNice;

  Greeting(this.entity, this.action, this.beNice);
}

class TestMigrator extends Migrator<Greeting> {
  final void Function(int, Greeting) onCommited;
  TestMigrator(this.onCommited) : super(
    2, // Latest version
    [
      Migration<Greeting>(
        1,
        (data) => Greeting(
          data["name"]!,
          data["action"]!,
          true
        )
      )
    ]
  );

  @override
  Future<Map<String, dynamic>?> loadRawData() async {
    return {
      "name": "Welt",
      "action": "welcome"
    };
  }

  @override
  Future<int?> loadVersion() async => 1;

  @override
  Greeting fromData(Map<String, dynamic> data) => Greeting(
    data["name"],
    data["action"],
    data["beNice"]
  );

  @override
  Greeting fromDefault() => Greeting(
    "Moxxy",
    "hug",
    true
  );

  @override
  Future<void> commit(int version, Greeting data) async {
    onCommited(version, data);
  }
}

class NoDataMigrator extends Migrator<Greeting> {
  final void Function(int, Greeting) onCommited;
  NoDataMigrator(this.onCommited) : super(
    2, // Latest version
    [
      Migration<Greeting>(
        1,
        (data) => Greeting(
          data["name"]!,
          data["action"]!,
          true
        )
      )
    ]
  );

  @override
  Future<Map<String, dynamic>?> loadRawData() async => null;

  @override
  Future<int?> loadVersion() async => null;

  @override
  Greeting fromData(Map<String, dynamic> data) => Greeting(
    data["name"],
    data["action"],
    data["beNice"]
  );

  @override
  Greeting fromDefault() => Greeting(
    "Moxxyv2",
    "hug_more",
    true
  );

  @override
  Future<void> commit(int version, Greeting data) async {
    onCommited(version, data);
  }
}

class MultipleStagedMigrator extends Migrator<Greeting> {
  final void Function(int, Greeting) onCommited;
  MultipleStagedMigrator(this.onCommited) : super(
    3, // Latest version
    [
      Migration<Greeting>(
        1,
        (data) => Greeting(
          data["name"]!,
          "hug1",
          true
        )
      ),
      Migration<Greeting>(
        2,
        (data) => Greeting(
          data["name"]!,
          "hug2",
          true
        )
      )
    ]
  );
  
  @override
  Future<Map<String, dynamic>?> loadRawData() async {
    return {
      "name": "Welt",
      "action": "welcome"
    };
  }

  @override
  Future<int?> loadVersion() async => 2;

  @override
  Greeting fromData(Map<String, dynamic> data) => Greeting(
    data["name"],
    data["action"],
    data["beNice"]
  );

  @override
  Greeting fromDefault() => Greeting(
    "Moxxyv2",
    "hug_more",
    true
  );

  @override
  Future<void> commit(int version, Greeting data) async {
    onCommited(version, data);
  }
}

void main() {
  test("Test a simple migration", () async {
      final mig = TestMigrator((v, g) {
          expect(v, 2);
      });
      final greeting = await mig.load();

      expect(greeting.entity, "Welt");
      expect(greeting.action, "welcome");
      expect(greeting.beNice, true);
  });

  test("Test loading data where there was none", () async {
      final mig = NoDataMigrator((v, g) {
          expect(v, 2);
      });
      final greeting = await mig.load();

      expect(greeting.entity, "Moxxyv2");
      expect(greeting.action, "hug_more");
      expect(greeting.beNice, true);
  });

  test("Test that only the correct stage is ran", () async {
      final mig = MultipleStagedMigrator((v, g) {
          expect(v, 3);
      });
      final greeting = await mig.load();

      expect(greeting.entity, "Welt");
      expect(greeting.action, "hug2");
      expect(greeting.beNice, true);
  });
}
