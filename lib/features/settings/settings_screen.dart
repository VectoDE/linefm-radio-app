import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/about/about_screen.dart';
import 'package:linefm_radio/features/about/radiogruppe_logo.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/features/consent/cast_consent.dart';
import 'package:linefm_radio/features/consent/google_consent.dart';
import 'package:linefm_radio/features/legal/external_link.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/settings/clear_storage.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/settings/sleep_timer_row.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/page_insets.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:linefm_radio/ui/widgets/settings_switch.dart';
import 'package:material_ui/material_ui.dart';

part 'settings_rows.dart';
part 'settings_sections.dart';

/// Settings (spec 4.1, web wording) with the native additions:
/// marquee, remember volume, play on start, appearance (system /
/// light / dark), tray (desktop only), sleep timer, alarm, statistics and
/// error reports (only with configured telemetry), clear storage,
/// About section and footer with "Ein Angebot von" + RadioGruppe logo.
///
/// Pure content without its own scaffold; the shell puts it into the frame.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final platform = ref.watch(platformInfoProvider);
    final telemetry = ref.watch(telemetryProvider);
    final consent = ref.watch(telemetryConsentProvider);
    // Width of the content area, not of the window: in the wide layout
    // the navigation sits on the left and the player on the right.
    return LayoutBuilder(
      builder: (context, box) => _list(context, ref, box.maxWidth, <Widget>[
        SectionHeading(l10n.settingsTitle),
        Divider(color: context.linefm.line),
        SettingsSwitch(
          title: l10n.settingMarqueeTitle,
          subtitle: l10n.settingMarqueeBody,
          value: settings.marquee,
          onChanged: (v) => notifier.update((s) => s.copyWith(marquee: v)),
        ),
        SettingsSwitch(
          title: l10n.settingVolumeTitle,
          subtitle: platform.isWeb
              ? l10n.settingVolumeBodyWeb
              : l10n.settingVolumeBodyDevice,
          value: settings.rememberVolume,
          onChanged: (v) =>
              notifier.update((s) => s.copyWith(rememberVolume: v)),
        ),
        SettingsSwitch(
          title: l10n.settingAutoplayTitle,
          subtitle: platform.isWeb
              ? l10n.settingAutoplayBodyWeb
              : l10n.settingAutoplayBody,
          value: settings.autoplay,
          onChanged: (v) => notifier.update((s) => s.copyWith(autoplay: v)),
        ),
        if (platform.isDesktop)
          SettingsSwitch(
            title: l10n.settingTrayTitle,
            subtitle: l10n.settingTrayBody,
            value: settings.closeToTray,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(closeToTray: v)),
          ),
        SettingsSwitch(
          title: l10n.settingArtworkTitle,
          subtitle: l10n.settingArtworkBody,
          value: settings.loadArtwork,
          onChanged: (v) => notifier.update((s) => s.copyWith(loadArtwork: v)),
        ),
        if (platform.isDesktop || platform.isWeb)
          SettingsSwitch(
            title: l10n.settingShortcutsTitle,
            subtitle: l10n.settingShortcutsBody,
            value: settings.keyboardShortcuts,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(keyboardShortcuts: v)),
          ),
        _ChoiceRow<AppThemeMode>(
          title: l10n.settingThemeTitle,
          selected: settings.themeMode,
          onChanged: (m) => notifier.update((s) => s.copyWith(themeMode: m)),
          segments: <ButtonSegment<AppThemeMode>>[
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.system,
              label: Text(l10n.themeSystem),
              icon: const Icon(Icons.brightness_auto_outlined, size: 18),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.light,
              label: Text(l10n.themeLight),
              icon: const Icon(Icons.light_mode_outlined, size: 18),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.dark,
              label: Text(l10n.themeDark),
              icon: const Icon(Icons.dark_mode_outlined, size: 18),
            ),
          ],
        ),
        // Language names in their own language (endonyms, identical in both ARB
        // files).
        _ChoiceRow<AppLanguage>(
          title: l10n.settingLanguageTitle,
          body: l10n.settingLanguageBody,
          selected: settings.language,
          onChanged: (l) => notifier.update((s) => s.copyWith(language: l)),
          segments: <ButtonSegment<AppLanguage>>[
            ButtonSegment<AppLanguage>(
              value: AppLanguage.system,
              label: Text(l10n.languageSystem),
              icon: const Icon(Icons.language, size: 18),
            ),
            ButtonSegment<AppLanguage>(
              value: AppLanguage.de,
              label: Text(l10n.languageGerman),
            ),
            ButtonSegment<AppLanguage>(
              value: AppLanguage.en,
              label: Text(l10n.languageEnglish),
            ),
          ],
        ),
        const SleepTimerRow(),
        const _AlarmRow(),
        if (telemetry.consentRequired)
          SettingsSwitch(
            title: l10n.settingTelemetryTitle,
            subtitle: consent == true
                ? l10n.settingTelemetryBodyOn
                : l10n.settingTelemetryBodyOff,
            value: consent == true,
            onChanged: (v) =>
                ref.read(telemetryConsentProvider.notifier).set(value: v),
          ),
        if (ref.watch(googleAnalyticsEnabledProvider))
          SettingsSwitch(
            title: l10n.settingGoogleTitle,
            subtitle: ref.watch(googleConsentProvider) == true
                ? l10n.settingGoogleBodyOn
                : l10n.settingGoogleBodyOff,
            value: ref.watch(googleConsentProvider) == true,
            onChanged: (v) =>
                ref.read(googleConsentProvider.notifier).set(value: v),
          ),
        // Native only: the web keeps covers in the browser HTTP cache.
        if (!kIsWeb)
          _ChoiceRow<CoverCacheLimit>(
            title: l10n.settingCoverCacheTitle,
            body: l10n.settingCoverCacheBody,
            selected: settings.coverCacheLimit,
            onChanged: (l) =>
                notifier.update((s) => s.copyWith(coverCacheLimit: l)),
            segments: <ButtonSegment<CoverCacheLimit>>[
              for (final limit in CoverCacheLimit.values)
                ButtonSegment<CoverCacheLimit>(
                  value: limit,
                  label: Text(l10n.coverCacheSizeMb(limit.megabytes)),
                ),
            ],
          ),
        if (ref.watch(browserCastBridgeProvider).supported)
          SettingsSwitch(
            title: l10n.settingCastTitle,
            subtitle: ref.watch(castConsentProvider) == true
                ? l10n.settingCastBodyOn
                : l10n.settingCastBodyOff,
            value: ref.watch(castConsentProvider) == true,
            onChanged: (v) =>
                ref.read(castConsentProvider.notifier).set(value: v),
          ),
        const _StorageSection(),
        _NavRow(title: l10n.settingAboutTitle, onTap: () => openAbout(context)),
        const SizedBox(height: 40),
        const _Footer(),
      ]),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    double width,
    List<Widget> children,
  ) {
    final side = PageInsets.side(context, width);
    return ListView(
      // 20 dp at the top like the station list, so that the heading sits
      // equally far below the header on all screens.
      padding: EdgeInsets.fromLTRB(
        side,
        LinefmSpace.gutter,
        side,
        LinefmSpace.xxl,
      ),
      children: children,
    );
  }
}
