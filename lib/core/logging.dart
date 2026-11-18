import 'package:flutter/foundation.dart';

/// Schlanker Logger. Gibt nur im Debug-Modus aus.
void logInfo(String message) {
  if (kDebugMode) debugPrint('[linefm] $message');
}

void logError(String message, [Object? error, StackTrace? stack]) {
  if (kDebugMode) {
    debugPrint('[linefm] ERROR $message${error == null ? '' : ': $error'}');
    if (stack != null) debugPrint(stack.toString());
  }
}
