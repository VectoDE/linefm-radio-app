part of 'alarm_screen.dart';

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LinefmSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(Icons.info_outline, size: 18, color: c.muted),
            ),
            const SizedBox(width: LinefmSpace.md),
            Expanded(
              child: Text(
                text,
                style: LinefmText.settingCopy.copyWith(color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dauerhafter Hinweis auf eine fehlende Systemfreigabe mit Knopf in die
/// passende Systemeinstellung.
class _PermissionNote extends StatelessWidget {
  const _PermissionNote({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.accent),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LinefmSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(text, style: LinefmText.settingCopy.copyWith(color: c.text)),
            const SizedBox(height: LinefmSpace.md),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
