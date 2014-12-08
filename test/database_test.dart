library tekartik_iodb.database_test;

// basically same as the io runner but with extra output
import 'package:tekartik_test/test_config_io.dart';
import 'package:tekartik_iodb/database_memory.dart';
import 'package:tekartik_iodb/database.dart';
import 'package:tekartik_io_tools/platform_utils.dart';
import 'package:path/path.dart';
import 'test_common.dart' as common;
import 'dart:async';

Future<Database> setupForTest(DatabaseFactory factory) {
  return common.setupForTest(factory, join(scriptDirPath, "tmp", "test.db"));
}

void main() {
  useVMConfiguration();
  defineTests(memoryDatabaseFactory);
}

void defineTests(DatabaseFactory factory) {

  group('database', () {

    String dbPath = join(scriptDirPath, "tmp", "test.db");

    group('open', () {
      Database db;

      setUp(() {
        return factory.deleteDatabase(dbPath).then((_) {

        });
      });

      tearDown(() {
        if (db != null) {
          db.close();
        }
      });

      test('open_no_version', () {
        return factory.openDatabase(dbPath).then((Database db) {
          expect(db.version, 1);
          expect(db.path, dbPath);
          db.close();
        });
      });

      test('open_version', () {
        return factory.openDatabase(dbPath, version: 1).then((Database db) {
          expect(db.version, 1);
          expect(db.path, dbPath);
          db.close();
        });
      });

      test('open_then_open_no_version', () {
        return factory.openDatabase(dbPath, version: 1).then((Database db) {

          return db.reOpen().then((Database db) {
            expect(db.path, dbPath);
            expect(db.version, 1);
            db.close();
          });
        });
      });

    });

    group('onVersionChanged', () {
      Database db;

      setUp(() {
        return factory.deleteDatabase(dbPath).then((_) {
        });
      });

      tearDown(() {
        if (db != null) {
          db.close();
        }
      });

      test('open_no_version', () {
        // save to make sure we've been through
        int _oldVersion;
        int _newVersion;
        _onVersionChanged(Database db, int oldVersion, int newVersion) {
          expect(db.version, oldVersion);
          _oldVersion = oldVersion;
          _newVersion = newVersion;
        }

        return factory.openDatabase(dbPath, onVersionChanged: _onVersionChanged).then((Database db) {
          expect(_oldVersion, 0);
          expect(_newVersion, 1);
          expect(db.version, 1);
          expect(db.path, dbPath);
          db.close();
        });
      });

      test('open_version', () {
        // save to make sure we've been through
        int _oldVersion;
        int _newVersion;
        _onVersionChanged(Database db, int oldVersion, int newVersion) {
          expect(db.version, oldVersion);
          _oldVersion = oldVersion;
          _newVersion = newVersion;
        }
        return factory.openDatabase(dbPath, version: 1, onVersionChanged: _onVersionChanged).then((Database db) {
          expect(_oldVersion, 0);
          expect(_newVersion, 1);
          expect(db.version, 1);
          expect(db.path, dbPath);
          db.close();
        });
      });

      test('open_then_open_no_version_or_same_version', () {
        return factory.openDatabase(dbPath, version: 1).then((Database db) {

          _onVersionChanged(Database db, int oldVersion, int newVersion) {
            fail("not changed");
          }
          return db.reOpen(onVersionChanged: _onVersionChanged).then((Database db) {
            expect(db.path, dbPath);
            expect(db.version, 1);
            db.close();
          }).then((_) {
            return db.reOpen(version: 1, onVersionChanged: _onVersionChanged).then((Database db) {
              expect(db.path, dbPath);
              expect(db.version, 1);
              db.close();
            });
          });
        });
      });

      test('open_then_open_new_version', () {
        return factory.openDatabase(dbPath, version: 1).then((Database db) {

// save to make sure we've been through
          int _oldVersion;
          int _newVersion;
          _onVersionChanged(Database db, int oldVersion, int newVersion) {
            expect(db.version, oldVersion);
            _oldVersion = oldVersion;
            _newVersion = newVersion;
          }
          return db.reOpen(version: 2, onVersionChanged: _onVersionChanged).then((Database db) {
            expect(_oldVersion, 1);
            expect(_newVersion, 2);
            expect(db.path, dbPath);
            expect(db.version, 2);
            db.close();
          });
        });
      });

    });
  });
}
