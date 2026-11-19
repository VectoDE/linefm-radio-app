import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// `navigator.userActivation.hasBeenActive`: `false`, solange der Nutzer
/// nicht geklickt, getippt oder eine Taste gedrueckt hat. Dann blockieren
/// Browser den Ton. Ohne die API (aeltere Browser) wird der Start versucht.
bool hasUserActivation() {
  final navigator = web.window.navigator;
  if (!(navigator as JSObject).has('userActivation')) return true;
  return navigator.userActivation.hasBeenActive;
}
