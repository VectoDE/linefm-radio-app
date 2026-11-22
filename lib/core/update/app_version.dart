/// Versionsrechnung für Releases und Updater (#104).
///
/// Reines Dart ohne Flutter, damit `tool/release/next_version.dart` es in der
/// CI ohne Flutter-Engine nutzen kann. Die Version steht nirgends fest im
/// Repository; der Release-Workflow berechnet sie bei jedem Merge auf main aus
/// dem letzten Release und dem Stand der offenen Issues.
library;

/// Release-Stufen in aufsteigender Reife. Ein Release fällt nie auf eine
/// niedrigere Stufe zurück.
enum ReleaseStage {
  alpha,
  beta,
  rc,
  stable;

  /// Stufe aus der Vorabkennung (`alpha`, `beta`, `rc`); ohne Kennung stabil.
  static ReleaseStage? fromPreRelease(String? pre) {
    if (pre == null || pre.isEmpty) return stable;
    final head = pre.split('.').first;
    for (final s in values) {
      if (s != stable && s.name == head) return s;
    }
    return null;
  }

  ReleaseStage atLeast(ReleaseStage other) =>
      index >= other.index ? this : other;
}

/// SemVer 2.0.0 (ohne Build-Metadaten im Vergleich).
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch, [this.preRelease = '']);

  static final RegExp _re = RegExp(
    r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
    r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
  );

  /// Liest `1.2.3`, `v1.2.3-rc.4` oder `1.2.3+5`; sonst null.
  static SemVer? tryParse(String input) {
    final m = _re.firstMatch(input.trim());
    if (m == null) return null;
    return SemVer(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      m.group(4) ?? '',
    );
  }

  final int major;
  final int minor;
  final int patch;
  final String preRelease;

  bool get isPreRelease => preRelease.isNotEmpty;

  /// Stufe der Version; null bei unbekannter Vorabkennung (z. B. `dev`).
  ReleaseStage? get stage => ReleaseStage.fromPreRelease(preRelease);

  /// Laufende Nummer der Vorabstufe (`alpha.7` -> 7), sonst 0.
  int get preNumber {
    final parts = preRelease.split('.');
    return parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  String get core => '$major.$minor.$patch';

  @override
  String toString() => isPreRelease ? '$core-$preRelease' : core;

  @override
  int compareTo(SemVer other) {
    for (final d in <int>[
      major - other.major,
      minor - other.minor,
      patch - other.patch,
    ]) {
      if (d != 0) return d.sign;
    }
    if (preRelease == other.preRelease) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    final a = preRelease.split('.');
    final b = other.preRelease.split('.');
    for (var i = 0; i < a.length && i < b.length; i++) {
      final na = int.tryParse(a[i]);
      final nb = int.tryParse(b[i]);
      int c;
      if (na != null && nb != null) {
        c = na.compareTo(nb);
      } else if (na != null) {
        c = -1;
      } else if (nb != null) {
        c = 1;
      } else {
        c = a[i].compareTo(b[i]);
      }
      if (c != 0) return c.sign;
    }
    return a.length.compareTo(b.length).sign;
  }

  bool operator >(SemVer o) => compareTo(o) > 0;
  bool operator <(SemVer o) => compareTo(o) < 0;

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);
}

/// Ein offenes Issue, reduziert auf seine Labels.
class OpenIssue {
  const OpenIssue(this.labels);
  final Set<String> labels;
}

const String featureLabel = 'typ:feature';
const String ownerOnlyLabel = 'nur-noch:jaybelife';

/// Stufe, die der Stand der offenen Issues erlaubt:
/// - offene Feature-Issues -> alpha,
/// - keine Feature-Issues mehr, aber andere offen -> beta,
/// - nur noch Issues mit `nur-noch:jaybelife` offen -> rc,
/// - nichts mehr offen -> stabil (1.0.0).
ReleaseStage stageFromIssues(Iterable<OpenIssue> open) {
  final list = open.toList();
  if (list.isEmpty) return ReleaseStage.stable;
  if (list.every((i) => i.labels.contains(ownerOnlyLabel))) {
    return ReleaseStage.rc;
  }
  if (list.any((i) => i.labels.contains(featureLabel))) {
    return ReleaseStage.alpha;
  }
  return ReleaseStage.beta;
}

/// Art der Änderung nach Conventional Commits, nur für Releases nach 1.0.0.
enum ChangeKind { patch, minor, major }

/// Liest die Änderungsart aus Commit- bzw. PR-Titeln.
ChangeKind changeKindOf(Iterable<String> subjects) {
  var kind = ChangeKind.patch;
  final breaking = RegExp(r'^[a-z]+(\([^)]*\))?!:');
  final feat = RegExp(r'^feat(\([^)]*\))?:');
  for (final s in subjects) {
    if (breaking.hasMatch(s) || s.contains('BREAKING CHANGE')) {
      return ChangeKind.major;
    }
    if (feat.hasMatch(s)) kind = ChangeKind.minor;
  }
  return kind;
}

/// Hoechste Release-Version unter [tags] (Vorabstufen alpha/beta/rc oder
/// stabil); andere Tags werden ignoriert. Null, wenn es keine gibt.
SemVer? latestRelease(Iterable<String> tags) {
  SemVer? best;
  for (final t in tags) {
    final v = SemVer.tryParse(t);
    if (v == null || v.stage == null) continue;
    if (best == null || v > best) best = v;
  }
  return best;
}

/// Erste Version, wenn es noch kein Release gibt.
const SemVer firstVersion = SemVer(0, 1, 0, 'alpha.1');

/// Nächste Release-Version.
///
/// - Ohne bisheriges Release: 0.1.0-alpha.1 (bzw. die erlaubte höhere Stufe).
/// - Gleiche Stufe: Vorabnummer + 1 (0.1.0-alpha.3 -> 0.1.0-alpha.4).
/// - Höhere Stufe: Nummer beginnt bei 1. alpha und beta laufen auf 0.1.0,
///   rc und stabil auf 1.0.0 (0.1.0-beta.9 -> 1.0.0-rc.1 -> 1.0.0).
/// - Nach einem stabilen Release: SemVer-Erhöhung nach [change].
SemVer nextVersion({
  required SemVer? last,
  required ReleaseStage allowed,
  ChangeKind change = ChangeKind.patch,
}) {
  if (last == null) {
    return _enter(const SemVer(0, 1, 0), allowed);
  }
  final current = last.stage ?? ReleaseStage.alpha;
  if (current == ReleaseStage.stable) {
    return switch (change) {
      ChangeKind.major => SemVer(last.major + 1, 0, 0),
      ChangeKind.minor => SemVer(last.major, last.minor + 1, 0),
      ChangeKind.patch => SemVer(last.major, last.minor, last.patch + 1),
    };
  }
  final target = allowed.atLeast(current);
  if (target == current) {
    return SemVer(
      last.major,
      last.minor,
      last.patch,
      '${current.name}.${last.preNumber + 1}',
    );
  }
  return _enter(SemVer(last.major, last.minor, last.patch), target);
}

SemVer _enter(SemVer base, ReleaseStage stage) {
  final b = (stage.index >= ReleaseStage.rc.index && base.major == 0)
      ? const SemVer(1, 0, 0)
      : base;
  if (stage == ReleaseStage.stable) return SemVer(b.major, b.minor, b.patch);
  return SemVer(b.major, b.minor, b.patch, '${stage.name}.1');
}

/// Update-Kanal = niedrigste Stufe, die eine Installation annimmt.
/// Standard ist die eigene Stufe der laufenden Version.
ReleaseStage defaultChannelFor(SemVer running) =>
    running.stage ?? ReleaseStage.alpha;

/// Ein Release aus der GitHub-Releases-API.
class ReleaseInfo {
  const ReleaseInfo({required this.tag, this.draft = false});
  final String tag;
  final bool draft;

  SemVer? get version => SemVer.tryParse(tag);
}

/// Neuestes Release, das zum [channel] passt und neuer als [running] ist.
/// Entwürfe und unlesbare Tags werden ignoriert.
ReleaseInfo? pickUpdate(
  Iterable<ReleaseInfo> releases, {
  required ReleaseStage channel,
  required SemVer running,
}) {
  ReleaseInfo? best;
  for (final r in releases) {
    final v = r.version;
    if (r.draft || v == null) continue;
    final s = v.stage;
    if (s == null || s.index < channel.index) continue;
    if (!(v > running)) continue;
    if (best == null || v > best.version!) best = r;
  }
  return best;
}
