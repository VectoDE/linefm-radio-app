import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/perf/perf_marks.dart';
import 'package:linefm_radio/core/perf/perf_marks_io.dart' as io_marks;
import 'package:linefm_radio/core/perf/perf_marks_stub.dart' as stub_marks;

void main() {
  test('Messpunkte sind ohne Schalter aus (Release fuer Nutzer)', () {
    expect(kPerfMarks, isFalse);
    // Darf nichts tun und nichts werfen.
    perfMark('first-frame');
  });

  test('IO: ohne LINEFM_PERF_FILE wird nichts geschrieben', () {
    final path = Platform.environment['LINEFM_PERF_FILE'];
    // Die Testumgebung setzt die Variable nicht; sonst ist der Test sinnlos.
    expect(path == null || path.isEmpty, isTrue);
    expect(() => io_marks.writeMark('main'), returnsNormally);
  });

  test('IO: writeMarkTo haengt Name und Zeit in Reihenfolge an', () {
    final dir = Directory.systemTemp.createTempSync('perf_marks');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = '${dir.path}${Platform.pathSeparator}marks.tsv';
    io_marks.writeMarkTo(file, 'main');
    io_marks.writeMarkTo(file, 'first-frame');
    final lines = File(file).readAsLinesSync();
    expect(lines, hasLength(2));
    expect(lines[0], startsWith('main\t'));
    expect(lines[1], startsWith('first-frame\t'));
    final t0 = int.parse(lines[0].split('\t')[1]);
    final t1 = int.parse(lines[1].split('\t')[1]);
    expect(t1, greaterThanOrEqualTo(t0));
  });

  test('Stub: ohne Wirkung', () {
    expect(() => stub_marks.writeMark('main'), returnsNormally);
  });

  test('IO: nicht schreibbarer Pfad wird geschluckt', () {
    final dir = Directory.systemTemp.createTempSync('perf_marks');
    addTearDown(() => dir.deleteSync(recursive: true));
    // Ein Ordner laesst sich nicht als Datei oeffnen.
    expect(() => io_marks.writeMarkTo(dir.path, 'main'), returnsNormally);
  });

  test('IO: logMark prints the line the Android measurement run parses', () {
    final lines = <String>[];
    runZoned(
      () => io_marks.logMark('first-frame', 1764000000123456),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );
    expect(lines, <String>['LINEFM_PERF first-frame 1764000000123456']);
  });
}
