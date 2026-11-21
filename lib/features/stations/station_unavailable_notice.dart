import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/deep_links.dart';
import 'package:material_ui/material_ui.dart';

/// Zeigt einen Hinweis, wenn ein Link (geteilter Link, Widget, Wecker-
/// Mitteilung) einen Sender oeffnen will, der nicht mehr in der Senderliste
/// steht (Issue #91). Gehoert unterhalb von `MaterialApp` (im `builder`).
class StationUnavailableNotice extends StatefulWidget {
  const StationUnavailableNotice({super.key, required this.child, this.links});

  final Widget child;

  /// Nur fuer Tests; Standard ist [DeepLinks.unavailable].
  @visibleForTesting
  final Stream<String>? links;

  @override
  State<StationUnavailableNotice> createState() =>
      _StationUnavailableNoticeState();
}

class _StationUnavailableNoticeState extends State<StationUnavailableNotice> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = (widget.links ?? DeepLinks.unavailable).listen((_) => _show());
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _show() {
    if (!mounted) return;
    final text = AppLocalizations.of(context).stationUnavailable;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
