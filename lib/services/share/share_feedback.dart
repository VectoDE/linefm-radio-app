import 'dart:async';

import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

enum ShareFeedbackKind {
  /// Text liegt in der Zwischenablage (Teilen nicht verfuegbar).
  copied,

  /// Datei liegt im Download-Ordner ([ShareFeedback.path]).
  savedTo,

  /// Teilen ist fehlgeschlagen.
  failed,
}

class ShareFeedback {
  const ShareFeedback(this.kind, {this.path});

  final ShareFeedbackKind kind;
  final String? path;
}

/// Rueckmeldungen des Teilen-Dienstes an die Oberflaeche. Statisch, damit der
/// Dienst (in `providers.dart` ohne Kontext gebaut) und der Hoerer in der App
/// ohne weitere Verdrahtung zusammenfinden.
class ShareFeedbackBus {
  ShareFeedbackBus._();

  static final StreamController<ShareFeedback> _controller =
      StreamController<ShareFeedback>.broadcast();

  static Stream<ShareFeedback> get stream => _controller.stream;

  static void emit(ShareFeedback feedback) => _controller.add(feedback);
}

/// Zeigt die Rueckmeldungen als SnackBar. Gehoert unterhalb von `MaterialApp`
/// (z. B. im `builder`), damit Sprache und ScaffoldMessenger vorhanden sind.
class ShareFeedbackListener extends StatefulWidget {
  const ShareFeedbackListener({super.key, required this.child, this.stream});

  final Widget child;

  /// Nur fuer Tests; Standard ist [ShareFeedbackBus.stream].
  @visibleForTesting
  final Stream<ShareFeedback>? stream;

  @override
  State<ShareFeedbackListener> createState() => _ShareFeedbackListenerState();
}

class _ShareFeedbackListenerState extends State<ShareFeedbackListener> {
  StreamSubscription<ShareFeedback>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = (widget.stream ?? ShareFeedbackBus.stream).listen(_show);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _show(ShareFeedback feedback) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final text = switch (feedback.kind) {
      ShareFeedbackKind.copied => l10n.shareCopied,
      ShareFeedbackKind.savedTo => l10n.favoritesExportSavedTo(
        feedback.path ?? '',
      ),
      ShareFeedbackKind.failed => l10n.shareFailed,
    };
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
