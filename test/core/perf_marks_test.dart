import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/perf/perf_marks.dart';
import 'package:linefm_radio/core/perf/perf_marks_io.dart' as io_marks;

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
}
