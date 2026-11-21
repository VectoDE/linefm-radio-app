// Berechnet die nächste Release-Version (#104). Aufruf aus release.yml:
//
//   dart run tool/release/next_version.dart \
//     --tags tags.txt --issues issues.json --subjects subjects.txt
//
// --tags      bisherige Release-Tags, einer je Zeile (leer: noch kein Release);
//             der hoechste nach SemVer gilt als letztes Release
// --issues    Ausgabe von `gh issue list --state open --json labels`
// --subjects  Commit-Betreffzeilen seit dem letzten Release, eine je Zeile
//
// Ausgabe (für $GITHUB_OUTPUT): version=…, tag=…, stage=…, prerelease=…
import 'dart:convert';
import 'dart:io';

import 'package:linefm_radio/core/update/app_version.dart';

void main(List<String> args) {
  final opts = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    opts[args[i].replaceFirst('--', '')] = args[i + 1];
  }
  final tagsPath = opts['tags'];
  final tags = tagsPath == null
      ? const <String>[]
      : File(tagsPath).readAsLinesSync();
  final last = latestRelease(tags);

  final issuesPath = opts['issues'];
  if (issuesPath == null) {
    stderr.writeln('--issues fehlt.');
    exit(2);
  }
  final raw = jsonDecode(File(issuesPath).readAsStringSync()) as List<dynamic>;
  final open = raw.map((e) {
    final labels = ((e as Map<String, dynamic>)['labels'] as List<dynamic>)
        .map((l) => (l as Map<String, dynamic>)['name'] as String)
        .toSet();
    return OpenIssue(labels);
  });

  final subjectsPath = opts['subjects'];
  final subjects = subjectsPath == null
      ? const <String>[]
      : File(subjectsPath).readAsLinesSync();

  final allowed = stageFromIssues(open);
  final next = nextVersion(
    last: last,
    allowed: allowed,
    change: changeKindOf(subjects),
  );
  stdout
    ..writeln('last=${last == null ? '' : 'v$last'}')
    ..writeln('version=$next')
    ..writeln('tag=v$next')
    ..writeln('stage=${next.stage!.name}')
    ..writeln('prerelease=${next.isPreRelease}');
}
