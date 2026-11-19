{{flutter_js}}
{{flutter_build_config}}

// Eigenes Bootstrap-Template (Spec 6.1). Kein Inline-Skript noetig, daher greift
// die CSP mit script-src 'self'. tool/web_postbuild.dart schreibt die gehashten
// Dateinamen in _flutter.buildConfig, verschiebt canvaskit/ nach
// canvaskit/<engineRevision>/ und ersetzt die Marke in der naechsten Zeile.
(function () {
  // COEP bleibt bewusst aus (Fremdbilder), Skwasm laeuft einthreadig; Warnung daher stumm.
  // Ersatzschriften (fehlende Zeichen, z. B. Emoji oder kyrillische Titel)
  // nicht von fonts.gstatic.com laden (L14, keine IP-Adresse an Google).
  // Die App bringt Poppins und Syncopate selbst mit; was dort fehlt, sucht
  // die Engine unter assets/fonts/fallback/ auf dem eigenen Server.
  var config = {
    suppressMultithreadingWarning: true,
    fontFallbackBaseUrl: 'assets/fonts/fallback/',
  };
  /*__CANVASKIT_BASE_URL__*/

  // Nach dem Start zeichnet Flutter die Oberflaeche. Die statische Huelle
  // bleibt fuer Crawler im DOM, ist aber fuer Screenreader und Tastatur
  // weg: kein zweites h1, keine unsichtbaren 0x0-Links im Tab-Weg (A11Y-03,
  // A11Y-07).
  function showApp() {
    var shell = document.getElementById('static-shell');
    if (!shell) return;
    shell.hidden = true;
    shell.setAttribute('aria-hidden', 'true');
    shell.setAttribute('inert', '');
  }

  _flutter.loader.load({
    config: config,
    onEntrypointLoaded: async function (engineInitializer) {
      var appRunner = await engineInitializer.initializeEngine(config);
      await appRunner.runApp();
      showApp();
    },
  });

  // Minimaler Service Worker nur fuer Installierbarkeit und Offline-Huelle.
  if ('serviceWorker' in navigator && window.isSecureContext) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('sw.js').catch(function () { /* ohne SW weiterlaufen */ });
    });
  }
})();
