@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/legacy_data_dir_io.dart';

void main() {
  late Directory root;
  late Directory from;
  late Directory to;

  setUp(() {
    root = Directory.systemTemp.createTempSync('lf_migration_');
    from = Directory('${root.path}/de.linefm/LINEFM Radio');
    to = Directory('${root.path}/LineFM Studios/LINEFM Radio');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('moves favorites and settings to the new folder', () async {
    from.createSync(recursive: true);
    File('${from.path}/shared_preferences.json')
        .writeAsStringSync('{"flutter.favorites":["main"]}');
    Directory('${from.path}/cache').createSync();
    File('${from.path}/cache/a.txt').writeAsStringSync('x');

    final result = await migrateDataDir(from: from, to: to);

    expect(result, DataDirMigration.moved);
    expect(
      File('${to.path}/shared_preferences.json').readAsStringSync(),
      '{"flutter.favorites":["main"]}',
    );
    expect(File('${to.path}/cache/a.txt').existsSync(), isTrue);
    expect(from.existsSync(), isFalse);
    expect(from.parent.existsSync(), isFalse, reason: 'empty old company dir');
  });

  test('runs only once: existing data in the new folder wins', () async {
    from.createSync(recursive: true);
    File('${from.path}/shared_preferences.json').writeAsStringSync('old');
    to.createSync(recursive: true);
    File('${to.path}/shared_preferences.json').writeAsStringSync('new');

    final result = await migrateDataDir(from: from, to: to);

    expect(result, DataDirMigration.targetHasData);
    expect(
      File('${to.path}/shared_preferences.json').readAsStringSync(),
      'new',
    );
    expect(File('${from.path}/shared_preferences.json').existsSync(), isTrue);
  });

  test('empty target folder does not block the move', () async {
    from.createSync(recursive: true);
    File('${from.path}/shared_preferences.json').writeAsStringSync('old');
    to.createSync(recursive: true);

    expect(await migrateDataDir(from: from, to: to), DataDirMigration.moved);
    expect(
      File('${to.path}/shared_preferences.json').readAsStringSync(),
      'old',
    );
  });

  test('no old folder: nothing happens', () async {
    expect(await migrateDataDir(from: from, to: to), DataDirMigration.noSource);
    expect(to.existsSync(), isFalse);
  });

  test(
    'copies recursively when the rename fails, then removes the source',
    () async {
      from.createSync(recursive: true);
      File('${from.path}/shared_preferences.json').writeAsStringSync('old');
      Directory('${from.path}/cache/deep').createSync(recursive: true);
      File('${from.path}/cache/deep/a.txt').writeAsStringSync('x');

      final result = await migrateDataDir(
        from: from,
        to: to,
        rename: (_, _) => throw const FileSystemException('cross-device'),
      );

      expect(result, DataDirMigration.copied);
      expect(
        File('${to.path}/shared_preferences.json').readAsStringSync(),
        'old',
      );
      expect(File('${to.path}/cache/deep/a.txt').readAsStringSync(), 'x');
      expect(from.existsSync(), isFalse);
      expect(from.parent.existsSync(), isFalse);
    },
  );

  group('migrateLegacyDataDir', () {
    test('moves the folder below APPDATA on Windows', () async {
      from.createSync(recursive: true);
      File('${from.path}/shared_preferences.json').writeAsStringSync('old');
      await migrateLegacyDataDir(
        windows: true,
        environment: <String, String>{'APPDATA': root.path},
      );
      expect(File('${to.path}/shared_preferences.json').existsSync(), isTrue);
      expect(from.existsSync(), isFalse);
    });

    test('never throws: a blocked target leaves the old folder', () async {
      from.createSync(recursive: true);
      File('${root.path}/LineFM Studios').writeAsStringSync('blocker');
      await migrateLegacyDataDir(
        windows: true,
        environment: <String, String>{'APPDATA': root.path},
      );
      expect(from.existsSync(), isTrue);
    });

    test('does nothing outside Windows', () async {
      from.createSync(recursive: true);
      await migrateLegacyDataDir(
        windows: false,
        environment: <String, String>{'APPDATA': root.path},
      );
      expect(from.existsSync(), isTrue);
    });

    test('does nothing without APPDATA', () async {
      from.createSync(recursive: true);
      await migrateLegacyDataDir(
        windows: true,
        environment: const <String, String>{},
      );
      expect(from.existsSync(), isTrue);
    });
  });
}
