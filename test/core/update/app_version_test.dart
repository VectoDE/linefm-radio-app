import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/update/app_version.dart';

OpenItem item(List<String> labels) => OpenItem(labels.toSet());
SemVer v(String s) => SemVer.tryParse(s)!;

void main() {
  group('SemVer', () {
    test('liest Tags mit und ohne v, Vorabstufe und Build', () {
      expect(v('v0.1.0-alpha.3').toString(), '0.1.0-alpha.3');
      expect(v('1.2.3+7').toString(), '1.2.3');
      expect(SemVer.tryParse('1.0'), isNull);
      expect(SemVer.tryParse('01.0.0'), isNull);
    });

    test('Rangfolge nach SemVer 2.0.0', () {
      final ordered = <String>[
        '0.1.0-alpha.1',
        '0.1.0-alpha.2',
        '0.1.0-alpha.10',
        '0.1.0-beta.1',
        '0.1.0',
        '1.0.0-rc.1',
        '1.0.0-rc.2',
        '1.0.0',
        '1.0.1',
        '1.1.0',
      ].map(v).toList();
      for (var i = 0; i + 1 < ordered.length; i++) {
        expect(ordered[i] < ordered[i + 1], isTrue, reason: '${ordered[i]}');
      }
    });

    test('Stufe und Nummer', () {
      expect(v('0.1.0-beta.4').stage, ReleaseStage.beta);
      expect(v('0.1.0-beta.4').preNumber, 4);
      expect(v('1.0.0').stage, ReleaseStage.stable);
      expect(v('0.0.0-dev').stage, isNull);
    });
  });

  group('Stufe aus offenen Tickets', () {
    test('offenes Feature-Ticket -> alpha', () {
      expect(
        stageFromItems([
          item(['typ:feature']),
          item(['bug']),
        ]),
        ReleaseStage.alpha,
      );
    });

    test('alle Features zu, anderes offen -> beta', () {
      expect(
        stageFromItems([
          item(['bug']),
          item(['nur-noch:linefm-studios']),
        ]),
        ReleaseStage.beta,
      );
    });

    test('nur noch nur-noch:linefm-studios offen -> rc', () {
      expect(
        stageFromItems([
          item(['nur-noch:linefm-studios', 'typ:feature']),
          item(['nur-noch:linefm-studios']),
        ]),
        ReleaseStage.rc,
      );
    });

    test('nichts offen -> stabil', () {
      expect(stageFromItems(const []), ReleaseStage.stable);
    });
  });

  group('Letztes Release', () {
    test('höchster Tag nach SemVer, fremde Tags ignoriert', () {
      expect(
        latestRelease([
          'v0.1.0-alpha.9',
          'v0.1.0-alpha.10',
          'v0.0.0-dev.3',
          'irgendwas',
          '',
        ]).toString(),
        '0.1.0-alpha.10',
      );
      expect(latestRelease(const []), isNull);
    });
  });

  group('Nächste Version', () {
    test('erstes Release ist 0.1.0-alpha.1', () {
      expect(
        nextVersion(last: null, allowed: ReleaseStage.alpha).toString(),
        '0.1.0-alpha.1',
      );
      expect(firstVersion.toString(), '0.1.0-alpha.1');
    });

    test('jeder Merge zählt die Vorabnummer hoch', () {
      expect(
        nextVersion(
          last: v('v0.1.0-alpha.3'),
          allowed: ReleaseStage.alpha,
        ).toString(),
        '0.1.0-alpha.4',
      );
    });

    test('Wechsel alpha -> beta -> rc -> 1.0.0', () {
      expect(
        nextVersion(
          last: v('0.1.0-alpha.9'),
          allowed: ReleaseStage.beta,
        ).toString(),
        '0.1.0-beta.1',
      );
      expect(
        nextVersion(
          last: v('0.1.0-beta.5'),
          allowed: ReleaseStage.rc,
        ).toString(),
        '1.0.0-rc.1',
      );
      expect(
        nextVersion(
          last: v('1.0.0-rc.2'),
          allowed: ReleaseStage.stable,
        ).toString(),
        '1.0.0',
      );
      expect(
        nextVersion(
          last: v('0.1.0-alpha.2'),
          allowed: ReleaseStage.stable,
        ).toString(),
        '1.0.0',
      );
    });

    test('keine Rückstufe, wenn ein Ticket wieder aufgeht', () {
      expect(
        nextVersion(
          last: v('1.0.0-rc.1'),
          allowed: ReleaseStage.alpha,
        ).toString(),
        '1.0.0-rc.2',
      );
    });

    test('nach 1.0.0 nach Conventional Commits', () {
      final last = v('1.0.0');
      expect(
        nextVersion(last: last, allowed: ReleaseStage.alpha).toString(),
        '1.0.1',
      );
      expect(
        nextVersion(
          last: last,
          allowed: ReleaseStage.stable,
          change: changeKindOf(['fix: x', 'feat(player): y']),
        ).toString(),
        '1.1.0',
      );
      expect(
        nextVersion(
          last: last,
          allowed: ReleaseStage.stable,
          change: changeKindOf(['feat!: neu']),
        ).toString(),
        '2.0.0',
      );
    });
  });

  group('Kanalfilter', () {
    final releases = <ReleaseInfo>[
      const ReleaseInfo(tag: 'v0.1.0-alpha.5'),
      const ReleaseInfo(tag: 'v0.1.0-beta.1'),
      const ReleaseInfo(tag: 'v0.1.0-beta.2', draft: true),
      const ReleaseInfo(tag: 'v1.0.0-rc.1'),
      const ReleaseInfo(tag: 'kaputt'),
    ];

    test('Standardkanal ist die eigene Stufe', () {
      expect(defaultChannelFor(v('0.1.0-alpha.2')), ReleaseStage.alpha);
      expect(defaultChannelFor(v('1.0.0')), ReleaseStage.stable);
    });

    test('alpha bekommt alles Neuere, ohne Entwürfe', () {
      expect(
        pickUpdate(
          releases,
          channel: ReleaseStage.alpha,
          running: v('0.1.0-alpha.2'),
        )?.tag,
        'v1.0.0-rc.1',
      );
    });

    test('stabil ignoriert Vorabversionen', () {
      expect(
        pickUpdate(
          releases,
          channel: ReleaseStage.stable,
          running: v('0.1.0-alpha.2'),
        ),
        isNull,
      );
    });

    test('nichts Neueres -> kein Update', () {
      expect(
        pickUpdate(
          releases,
          channel: ReleaseStage.beta,
          running: v('1.0.0-rc.1'),
        ),
        isNull,
      );
    });
  });
}
