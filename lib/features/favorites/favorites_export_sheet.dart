import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Export-Einstieg: Auswahl CSV oder Text, danach uebergibt der
/// `ShareService` (P21) die Datei bzw. den Text an Teilen-Dialog, Download oder
/// Download-Ordner (je Plattform). Meldet `export_favorites`.
Future<void> startFavoritesExport(BuildContext context, WidgetRef ref) async {
  final favorites = ref.read(favoritesProvider);
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (favorites.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.favoritesExportEmpty)));
    return;
  }

  final format = await showModalBottomSheet<ExportFormat>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.linefm.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(LinefmMetrics.radiusMiniPlayer),
      ),
    ),
    builder: (context) => NamedSheet(
      label: AppLocalizations.of(context).favoritesExport,
      child: const _ExportSheet(),
    ),
  );
  if (format == null) return;

  try {
    await ref
        .read(shareServiceProvider)
        .exportFavorites(ref.read(favoritesProvider), format);
    unawaited(
      ref.read(telemetryProvider).event('export_favorites', <String, Object>{
        'format': format.name,
      }),
    );
  } on Object {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.favoritesExportFailed)),
    );
  }
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.favoritesExport,
                  style: LinefmText.settingTitle.copyWith(
                    color: c.text,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            _Option(
              icon: FontAwesomeIcons.fileCsv,
              label: l10n.favoritesExportCsv,
              format: ExportFormat.csv,
            ),
            _Option(
              icon: FontAwesomeIcons.fileLines,
              label: l10n.favoritesExportText,
              format: ExportFormat.text,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.format,
  });

  final FaIconData icon;
  final String label;
  final ExportFormat format;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: LinefmMetrics.minTarget,
      leading: FaIcon(icon, size: 20, color: c.muted),
      title: Text(label, style: LinefmText.listTitle.copyWith(color: c.text)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
      onTap: () => Navigator.of(context).pop(format),
    );
  }
}
