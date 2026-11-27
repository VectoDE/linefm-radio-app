part of 'settings_screen.dart';

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
