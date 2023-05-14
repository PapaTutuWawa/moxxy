import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/migration.dart';
import 'package:test/test.dart';

import 'helpers/logging.dart';

void main() {
  initLogger();

  group('runMigrations', () {
    test('The consumed list must always be ordered', () async {
      var counter = 1;
      await runMigrations<int>(
        Logger('TestLogger'),
        1,
        [
          DatabaseMigration(4, (_) async {
            expect(counter, 3);
            counter++;
          }),
          DatabaseMigration(2, (_) async {
            expect(counter, 1);
            counter++;
          }),
          DatabaseMigration(3, (_) async {
            expect(counter, 2);
            counter++;
          }),
        ],
        1,
      );
    });

    test('Run only relevant migrations', () async {
      var counter = 2;
      await runMigrations<int>(
        Logger('TestLogger'),
        1,
        [
          DatabaseMigration(4, (_) async {
            expect(counter, 3);
            counter++;
          }),
          DatabaseMigration(2, (_) async {
            // This must never be called
            expect(true, false);
          }),
          DatabaseMigration(3, (_) async {
            expect(counter, 2);
            counter++;
          }),
        ],
        2,
      );
    });
  });
}
