// The Flutter loader probes the browser when it is evaluated (WebGL context,
// Wasm feature checks). Wrapped in a function, that work runs only when the
// engine actually starts (see start() below), not on page load.
function linefmEvaluateFlutterLoader() {
{{flutter_js}}
{{flutter_build_config}}
}

// Eigenes Bootstrap-Template (Spec 6.1). Kein Inline-Skript noetig, daher greift
// die CSP mit script-src 'self'. tool/web_postbuild.dart schreibt die gehashten
// Dateinamen in _flutter.buildConfig, verschiebt canvaskit/ nach
// canvaskit/<engineRevision>/ und ersetzt die Marke in der naechsten Zeile.
(function () {
  // COEP bleibt bewusst aus (Fremdbilder), Skwasm laeuft einthreadig; Warnung daher stumm.
  // Ersatzschriften (fehlende Zeichen, z. B. Emoji oder kyrillische Titel)
  // nicht von fonts.gstatic.com laden (keine IP-Adresse an Google).
  // Die App bringt Poppins und Syncopate selbst mit; was dort fehlt, sucht
  // die Engine unter assets/fonts/fallback/ auf dem eigenen Server.
  // Nonce for the style elements the engine creates (CSP style-src); the
  // postbuild replaces the placeholder with a random value per build.
  var config = {
    nonce: '__CSP_STYLE_NONCE__',
    suppressMultithreadingWarning: true,
    fontFallbackBaseUrl: 'assets/fonts/fallback/',
  };
  /*__CANVASKIT_BASE_URL__*/

  // Nach dem Start zeichnet Flutter die Oberflaeche. Die statische Huelle
  // bleibt fuer Crawler im DOM, ist aber fuer Screenreader und Tastatur
  // weg: kein zweites h1, keine unsichtbaren 0x0-Links im Tab-Weg.
  function showApp() {
    var shell = document.getElementById('static-shell');
    if (!shell) return;
    // Fade like the in-app loader (LoaderGate, 150 ms), then take it out.
    shell.classList.add('leaving');
    setTimeout(function () { shell.hidden = true; }, 150);
    shell.setAttribute('aria-hidden', 'true');
    shell.setAttribute('inert', '');
  }

  // runApp resolves before Flutter has painted anything; hiding the shell
  // right away showed a few empty frames between the two loading screens.
  // The shell sits above the Flutter view (z-index in index.html) until the
  // view holds a rendered canvas, then two more frames so it is on screen.
  function whenFirstFramePainted(done) {
    var deadline = performance.now() + 3000;
    function check() {
      // The rendered scene lives in the shadow root of flt-glass-pane.
      var pane = document.querySelector('flutter-view > flt-glass-pane');
      var root = pane && (pane.shadowRoot || pane);
      var painted = root && root.querySelector('flt-scene canvas');
      if (painted || performance.now() > deadline) {
        requestAnimationFrame(function () { requestAnimationFrame(done); });
      } else {
        requestAnimationFrame(check);
      }
    }
    requestAnimationFrame(check);
  }

  // Start the engine on intent, not on page load. Downloading, compiling and
  // initialising the Wasm engine blocks the main thread for several seconds on
  // mid-range phones; first-time visitors see the static shell (the branded
  // loading screen with a start button and the legal links) until they
  // interact. The button replaces the loading dots via CSS in index.html. Returning visitors, deep
  // links and the installed app start right away. Audio needs a user gesture
  // in any case, so the first tap costs no extra step before playback.
  var started = false;
  var STARTED_KEY = 'linefm.started';
  var TRIGGERS = ['pointerdown', 'keydown', 'touchstart'];

  function onIntent(event) {
    // Links in the shell (imprint, privacy, partner sites) navigate away;
    // starting the engine for them would only waste data.
    var target = event.target;
    if (target && target.closest && target.closest('a')) return;
    start();
  }

  function start() {
    if (started) return;
    started = true;
    TRIGGERS.forEach(function (type) {
      window.removeEventListener(type, onIntent, true);
    });
    try { localStorage.setItem(STARTED_KEY, '1'); } catch (e) { /* storage blocked */ }
    var button = document.getElementById('start-app');
    var dots = document.getElementById('shell-loading');
    if (button) button.hidden = true;
    if (dots) dots.hidden = false;
    linefmEvaluateFlutterLoader();
    _flutter.loader.load({
      config: config,
      onEntrypointLoaded: async function (engineInitializer) {
        var appRunner = await engineInitializer.initializeEngine(config);
        await appRunner.runApp();
        whenFirstFramePainted(showApp);
      },
    });
  }

  function startsRightAway() {
    try {
      if (localStorage.getItem(STARTED_KEY) === '1') return true;
    } catch (e) { /* storage blocked: treat as first visit */ }
    if (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches) return true;
    // Any path below the base (station, settings, ...) is a deep link.
    var base = new URL(document.baseURI).pathname;
    var path = location.pathname;
    return path !== base && path !== base + 'index.html';
  }

  if (startsRightAway()) {
    start();
  } else {
    var button = document.getElementById('start-app');
    if (button) {
      button.addEventListener('click', start);
      button.classList.add('ready');
    }
    TRIGGERS.forEach(function (type) {
      window.addEventListener(type, onIntent, { capture: true, passive: true });
    });
  }

  // Minimaler Service Worker nur fuer Installierbarkeit und Offline-Huelle.
  if ('serviceWorker' in navigator && window.isSecureContext) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('sw.js').catch(function () { /* ohne SW weiterlaufen */ });
    });
  }
})();
