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
          Migration(4, (_) async {
            expect(counter, 3);
            counter++;
          }),
          Migration(2, (_) async {
            expect(counter, 1);
            counter++;
          }),
          Migration(3, (_) async {
            expect(counter, 2);
            counter++;
          }),
        ],
        1,
        'test',
      );
    });

    test('Run only relevant migrations', () async {
      var counter = 2;
      await runMigrations<int>(
        Logger('TestLogger'),
        1,
        [
          Migration(4, (_) async {
            expect(counter, 3);
            counter++;
          }),
          Migration(2, (_) async {
            // This must never be called
            expect(true, false);
          }),
          Migration(3, (_) async {
            expect(counter, 2);
            counter++;
          }),
        ],
        2,
        'test',
      );
    });

    test('Commit when a migration has run', () async {
      var hasRun = false;
      await runMigrations<int>(
        Logger('TestLogger'),
        1,
        [
          Migration(4, (_) async {}),
          Migration(2, (_) async {}),
          Migration(3, (_) async {}),
        ],
        2,
        'test',
        commitVersion: (version) async {
          expect(version, 4);
          hasRun = true;
        },
      );

      expect(hasRun, true);
    });

    test('Do not commit when no migration has run', () async {
      var hasRun = false;
      await runMigrations<int>(
        Logger('TestLogger'),
        1,
        [
          Migration(4, (_) async {}),
          Migration(2, (_) async {}),
          Migration(3, (_) async {}),
        ],
        4,
        'test',
        commitVersion: (version) async {
          hasRun = true;
        },
      );

      expect(hasRun, false);
    });
  });
}
