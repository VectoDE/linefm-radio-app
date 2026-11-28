import 'package:flutter/services.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

const PlatformInfo web = PlatformInfo(
  isWeb: true,
  platform: TargetPlatform.windows,
);

/// Host mit bereits bestaetigtem Speicher-Hinweis: die Einwilligungs-Tests
/// sollen nicht vom Popup des Speicher-Hinweises (App) verdeckt werden.
FeatureHost confirmedHost({
  AppConfig config = const AppConfig(),
  LegalAssetLoader? legalLoader,
}) {
  final host = FeatureHost(config: config, legalLoader: legalLoader);
  host.prefs.setStorageConsent(value: true).ignore();
  return host;
}
