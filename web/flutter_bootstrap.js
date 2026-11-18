{{flutter_js}}
{{flutter_build_config}}

// Eigenes Bootstrap-Template (Spec 6.1). Kein Inline-Skript noetig, daher greift
// die CSP mit script-src 'self'. tool/web_postbuild.dart schreibt die gehashten
// Dateinamen in _flutter.buildConfig, verschiebt canvaskit/ nach
// canvaskit/<engineRevision>/ und ersetzt die Marke in der naechsten Zeile.
(function () {
  var config = {};
  /*__CANVASKIT_BASE_URL__*/

  function showApp() {
    var shell = document.getElementById('static-shell');
    if (shell) shell.hidden = true;
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
  if ('serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost')) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('sw.js').catch(function () { /* ohne SW weiterlaufen */ });
    });
  }
})();
