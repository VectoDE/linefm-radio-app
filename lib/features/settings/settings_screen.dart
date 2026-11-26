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
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:linefm_radio/ui/widgets/settings_switch.dart';
import 'package:material_ui/material_ui.dart';

/// Einstellungen (Spec 4.1, Web-Wortlaut) mit den nativen Ergaenzungen:
/// Lauftext, Lautstaerke merken, Beim Start abspielen, Darstellung (System /
/// Hell / Dunkel), Tray (nur Desktop), Sleeptimer, Wecker, Statistik und
/// Fehlerberichte (nur bei konfigurierter Telemetrie), Speicher loeschen,
/// Ueber-Bereich und Footer mit "Ein Angebot von" + RadioGruppe-Logo.
///
/// Reiner Inhalt ohne eigenes Scaffold; die Shell setzt ihn in den Rahmen.
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
    // Breite der Inhaltsflaeche, nicht des Fensters: im breiten Layout
    // stehen links die Navigation und rechts der Player (A11Y-06).
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
        // Sprachnamen in ihrer eigenen Sprache (Endonyme, in beiden ARB-
        // Dateien gleich).
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
    final side = width > 760 ? (width - 720) / 2 : 20.0;
    return ListView(
      // Oben 20 dp wie die Stationsliste, damit die Ueberschrift auf allen
      // Screens gleich weit unter dem Header sitzt.
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

/// Auswahlzeile mit Segmenten (Darstellung, Sprache): Titel als Ueberschrift,
/// optional eine Erklaerung, darunter die Segmente. Der Screenreader meldet
/// je Segment Schaltflaeche und gewaehlten Zustand.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.body,
  });

  final String title;
  final String? body;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              headingLevel: 2,
              container: true,
              child: Text(
                title,
                style: LinefmText.settingTitle.copyWith(color: c.text),
              ),
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: LinefmSpace.xs),
              Text(
                body!,
                style: LinefmText.settingCopy.copyWith(color: c.muted),
              ),
            ],
            const SizedBox(height: LinefmSpace.md),
            LayoutBuilder(
              // Zu schmal fuer drei Segmente nebeneinander (320 dp, grosse
              // Schrift): untereinander statt Buchstabe fuer Buchstabe.
              builder: (context, box) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<T>(
                  direction:
                      box.maxWidth <
                          330 * MediaQuery.textScalerOf(context).scale(1)
                      ? Axis.vertical
                      : Axis.horizontal,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    foregroundColor: c.text,
                    backgroundColor: Colors.transparent,
                    selectedForegroundColor: c.onAccent,
                    selectedBackgroundColor: c.accent,
                    side: BorderSide(color: c.muted),
                    textStyle: LinefmText.listMeta,
                    minimumSize: const Size(0, LinefmMetrics.minTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        LinefmMetrics.radiusLogo,
                      ),
                    ),
                  ),
                  // Der Zustand "ausgewaehlt" steht im Label-Teil, damit er mit
                  // in den Schaltflaechen-Knoten des Screenreaders faellt.
                  segments: <ButtonSegment<T>>[
                    for (final s in segments)
                      ButtonSegment<T>(
                        value: s.value,
                        icon: s.icon,
                        enabled: s.enabled,
                        label: Semantics(
                          selected: s.value == selected,
                          inMutuallyExclusiveGroup: true,
                          child: s.label,
                        ),
                      ),
                  ],
                  selected: <T>{selected},
                  onSelectionChanged: (s) => onChanged(s.first),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zeile "Wecker" mit naechster Weckzeit; oeffnet den Wecker-Screen.
class _AlarmRow extends ConsumerWidget {
  const _AlarmRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(alarmProvider);
    final now = ref.watch(clockProvider).now();
    final next = AlarmSchedule.nextOf(rules, now);
    return _NavRow(
      title: l10n.settingAlarmTitle,
      subtitle: next == null
          ? l10n.settingAlarmBodyOff
          : l10n.alarmNext(formatAlarmTime(context, l10n, next, now)),
      onTap: () => openAlarm(context),
    );
  }
}

/// Zeile mit Titel, optionaler Beschreibung und Pfeil.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: title,
        hint: subtitle,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: LinefmMetrics.minTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: LinefmText.settingTitle.copyWith(
                            color: c.text,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: LinefmSpace.xs),
                          Text(
                            subtitle!,
                            style: LinefmText.settingCopy.copyWith(
                              color: c.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: LinefmSpace.xl),
                  Icon(Icons.chevron_right, color: c.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abschnitt "Speicher" mit "Speicher loeschen" (mit Rueckfrage).
class _StorageSection extends ConsumerWidget {
  const _StorageSection();

  Future<void> _confirmAndClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => NamedDialog(
        label: l10n.clearStorageConfirmTitle,
        child: AlertDialog(
          semanticLabel: l10n.clearStorageConfirmTitle,
          title: Text(l10n.clearStorageConfirmTitle),
          content: Text(l10n.clearStorageConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDelete),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await clearAppStorage(ref);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.clearStorageDone)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final button = OutlinedButton.icon(
      onPressed: () => _confirmAndClear(context, ref),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: Text(l10n.settingStorageClear),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          headingLevel: 2,
          container: true,
          child: Text(
            l10n.settingStorageTitle,
            style: LinefmText.settingTitle.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: LinefmSpace.xs),
        Text(
          l10n.settingStorageBody,
          style: LinefmText.settingCopy.copyWith(color: c.muted),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
        child: LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  copy,
                  const SizedBox(height: LinefmSpace.lg),
                  button,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: copy),
                const SizedBox(width: LinefmSpace.xl),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Ein Angebot von" + RadioGruppe-Logo, darunter Website, Impressum und
/// Datenschutz (die Rechtstexte oeffnen in der App).
class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    Widget link(String label, Uri url, VoidCallback onTap) => SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        link: true,
        linkUrl: url,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LinefmMetrics.minTarget,
            minWidth: LinefmMetrics.minTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.sm),
              child: Text(
                label,
                style: LinefmText.listTitle.copyWith(
                  color: c.text,
                  fontSize: LinefmType.caption,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final dot = ExcludeSemantics(
      child: Text('·', style: TextStyle(color: c.muted)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RadioGruppeCredit(),
        Divider(color: c.line, height: 48),
        Semantics(
          container: true,
          label: l10n.footerLinksLabel,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              link(
                l10n.footerWebsite,
                Uri.parse(websiteUrl),
                () => openExternalUrl(context, ref, websiteUrl),
              ),
              dot,
              link(
                l10n.footerImprint,
                LegalKind.imprint.webUri,
                () => openLegal(context, LegalKind.imprint),
              ),
              dot,
              link(
                l10n.footerPrivacy,
                LegalKind.privacy.webUri,
                () => openLegal(context, LegalKind.privacy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
