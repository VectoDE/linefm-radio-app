import 'dart:convert';

/// Installationsbereich.
enum Scope {
  /// Nur für den angemeldeten Benutzer, ohne Administratorrechte.
  user,

  /// Für alle Benutzer des Rechners, braucht Administratorrechte (UAC).
  machine;

  static Scope parse(Object? value) =>
      value == 'machine' ? Scope.machine : Scope.user;

  String get arg => name;
}

/// Bereits vorhandene Installation (aus der Registry, von der Engine gelesen).
class Installed {
  const Installed({
    required this.version,
    required this.scope,
    required this.dir,
    required this.desktop,
    required this.startMenu,
    required this.autostart,
  });

  final String version;
  final Scope scope;
  final String dir;
  final bool desktop;
  final bool startMenu;
  final bool autostart;

  static Installed? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    return Installed(
      version: _string(json['version']),
      scope: Scope.parse(json['scope']),
      dir: _string(json['dir']),
      desktop: json['desktop'] == true,
      startMenu: json['startMenu'] == true,
      autostart: json['autostart'] == true,
    );
  }
}

/// Startdaten der Oberfläche. Der Setup-Stub schreibt sie als
/// `context.json` in den privaten Temp-Ordner und übergibt den Pfad mit
/// `--context`.
class SetupContext {
  const SetupContext({
    required this.mode,
    required this.engine,
    required this.productName,
    required this.version,
    required this.publisher,
    required this.exeName,
    required this.url,
    required this.installedUser,
    required this.installedMachine,
    required this.defaultScope,
    required this.userDir,
    required this.machineDir,
    required this.defaultDesktop,
    required this.defaultStartMenu,
    required this.defaultAutostart,
    required this.elevated,
    required this.sizeBytes,
    required this.target,
  });

  factory SetupContext.fromJson(Map<String, Object?> json) {
    final product = _map(json['product']);
    final installed = _map(json['installed']);
    final defaults = _map(json['defaults']);
    return SetupContext(
      mode: json['mode'] == 'uninstall'
          ? SetupMode.uninstall
          : SetupMode.install,
      engine: _string(json['engine']),
      productName: _string(product['name'], 'LINEFM Radio'),
      version: _string(product['version']),
      publisher: _string(product['publisher']),
      exeName: _string(product['exe'], 'linefm_radio.exe'),
      url: _string(product['url']),
      installedUser: Installed.fromJson(installed['user']),
      installedMachine: Installed.fromJson(installed['machine']),
      defaultScope: Scope.parse(defaults['scope']),
      userDir: _string(defaults['userDir']),
      machineDir: _string(defaults['machineDir']),
      defaultDesktop: defaults['desktop'] != false,
      defaultStartMenu: defaults['startMenu'] != false,
      defaultAutostart: defaults['autostart'] == true,
      elevated: json['elevated'] == true,
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes']! as int : 0,
      target: _string(json['target']),
    );
  }

  static SetupContext parse(String text) {
    final Object? json = jsonDecode(text);
    if (json is! Map<String, Object?>) {
      throw const FormatException('context.json ist kein Objekt');
    }
    return SetupContext.fromJson(json);
  }

  final SetupMode mode;

  /// Pfad der Engine (setup.exe bzw. Kopie von uninstall.exe).
  final String engine;
  final String productName;
  final String version;
  final String publisher;
  final String exeName;
  final String url;
  final Installed? installedUser;
  final Installed? installedMachine;
  final Scope defaultScope;
  final String userDir;
  final String machineDir;
  final bool defaultDesktop;
  final bool defaultStartMenu;
  final bool defaultAutostart;

  /// Oberfläche läuft bereits erhöht (dann keine UAC-Abfrage mehr nötig).
  final bool elevated;

  /// Größe der Programmdateien in Bytes.
  final int sizeBytes;

  /// Deinstallation: Installationsordner.
  final String target;

  /// Vorhandene Installation (Benutzer vor Rechner, wie die Engine).
  Installed? get installed => installedUser ?? installedMachine;
}

enum SetupMode { install, uninstall }

String _string(Object? value, [String fallback = '']) =>
    value is String && value.isNotEmpty ? value : fallback;

Map<String, Object?> _map(Object? value) =>
    value is Map<String, Object?> ? value : const <String, Object?>{};

/// Vergleich nach SemVer-Vorrang wie die Engine (`CompareVersions`).
int compareVersions(String a, String b) {
  (List<String>, String) split(String v) {
    final plus = v.indexOf('+');
    if (plus >= 0) v = v.substring(0, plus);
    final dash = v.indexOf('-');
    final core = dash >= 0 ? v.substring(0, dash) : v;
    final pre = dash >= 0 ? v.substring(dash + 1) : '';
    return (core.split('.'), pre);
  }

  int cmpPart(String x, String y) {
    final nx = int.tryParse(x);
    final ny = int.tryParse(y);
    if (nx != null && ny != null) return nx.compareTo(ny).sign;
    if (nx != null) return -1;
    if (ny != null) return 1;
    return x.compareTo(y).sign;
  }

  final (coreA, preA) = split(a);
  final (coreB, preB) = split(b);
  for (var i = 0; i < 3; i++) {
    final x = i < coreA.length ? coreA[i] : '0';
    final y = i < coreB.length ? coreB[i] : '0';
    final c = cmpPart(x, y);
    if (c != 0) return c;
  }
  if (preA.isEmpty && preB.isEmpty) return 0;
  if (preA.isEmpty) return 1;
  if (preB.isEmpty) return -1;
  final pa = preA.split('.');
  final pb = preB.split('.');
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final c = cmpPart(pa[i], pb[i]);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length).sign;
}
