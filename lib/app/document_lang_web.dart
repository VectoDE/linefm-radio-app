import 'package:web/web.dart' as web;

/// Setzt das lang-Attribut des Dokuments (z. B. `de`, `en`).
void setDocumentLang(String languageCode) {
  final root = web.document.documentElement;
  if (root != null && root.getAttribute('lang') != languageCode) {
    root.setAttribute('lang', languageCode);
  }
}
