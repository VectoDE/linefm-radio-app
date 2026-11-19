import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plattform fuer plattformabhaengige Texte und Zeilen (Web-Wortlaut,
/// Tray nur Desktop, Wecker-Hinweise). Tests ueberschreiben den Provider.
@immutable
class PlatformInfo {
  const PlatformInfo({required this.isWeb, required this.platform});

  factory PlatformInfo.current() =>
      PlatformInfo(isWeb: kIsWeb, platform: defaultTargetPlatform);

  final bool isWeb;
  final TargetPlatform platform;

  bool get isAndroid => !isWeb && platform == TargetPlatform.android;
  bool get isIOS => !isWeb && platform == TargetPlatform.iOS;
  bool get isDesktop =>
      !isWeb &&
      (platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS);
}

final platformInfoProvider = Provider<PlatformInfo>(
  (ref) => PlatformInfo.current(),
);
