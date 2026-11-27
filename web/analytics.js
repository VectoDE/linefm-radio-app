// Reichweitenmessung mit Google (GA4 / Google Tag Manager), nur Web.
//
// Grundsatz: Ohne Einwilligung geht keine einzige Anfrage an Google.
//  - Beim Laden setzt diese Datei nur den Consent-Mode-v2-Standard "denied" in
//    die Datenschicht (window.dataLayer, ein einfaches Array). Das ist reines
//    JavaScript ohne Netzwerkzugriff; gtm.js bzw. gtag.js liest die Eintraege
//    erst, wenn es geladen wird.
//  - Die App (Dart, lib/services/analytics/) ruft configure(gtmId, ga4Id) mit den
//    Werten aus config/app.json (--dart-define). Ohne IDs passiert nichts.
//  - Erst grant() (Nutzer stimmt zu) setzt analytics_storage auf "granted" und
//    laedt gtm.js (mit GTM_ID) bzw. gtag.js (nur GA4_MEASUREMENT_ID). Werbe-
//    Kategorien (ad_*) bleiben immer "denied".
//  - deny()/reset() setzen analytics_storage zurueck und loeschen die _ga-/_gid-/
//    _gat-Cookies. War gtm.js bzw. gtag.js in dieser Sitzung schon geladen, wird
//    GA4 zusaetzlich per window['ga-disable-<ID>'] abgeschaltet und die Seite
//    neu geladen: Ein geladenes Skript laesst sich nicht entladen und koennte im
//    Consent Mode sonst weiter cookielose Pings senden. Nach dem Neuladen gilt
//    "denied", es wird nichts mehr von Google geladen.
// Die Entscheidung liegt in localStorage unter KEY ("granted" | "denied"); das
// Speichern der Entscheidung selbst ist technisch notwendig (§ 25 Abs. 2 TDDDG).
// Die CSP erlaubt googletagmanager.com / google-analytics.com nur, wenn beim Build
// IDs gesetzt waren (tool/web_postbuild.dart). Getestet: tool/a11y/analytics_net.mjs.
(function () {
  'use strict';
  var KEY = 'linefm.googleAnalytics';
  var GTM_RE = /^GTM-[A-Z0-9]{4,12}$/;
  var GA4_RE = /^G-[A-Z0-9]{4,16}$/;
  var w = window;
  w.dataLayer = w.dataLayer || [];
  function gtag() {
    w.dataLayer.push(arguments);
  }
  gtag('consent', 'default', {
    ad_storage: 'denied',
    ad_user_data: 'denied',
    ad_personalization: 'denied',
    analytics_storage: 'denied',
    functionality_storage: 'denied',
    personalization_storage: 'denied',
    security_storage: 'denied',
  });
  gtag('set', 'ads_data_redaction', true);

  var cfg = { gtm: '', ga4: '' };
  var loaded = false;

  function read() {
    try {
      var v = w.localStorage.getItem(KEY);
      return v === 'granted' || v === 'denied' ? v : '';
    } catch (e) {
      return '';
    }
  }
  function write(v) {
    try {
      if (v) w.localStorage.setItem(KEY, v);
      else w.localStorage.removeItem(KEY);
    } catch (e) {
      /* privater Modus: Entscheidung gilt nur fuer diese Sitzung */
    }
  }
  function configured() {
    return cfg.gtm !== '' || cfg.ga4 !== '';
  }
  function inject(src) {
    var s = document.createElement('script');
    s.async = true;
    s.src = src;
    document.head.appendChild(s);
  }
  function load() {
    if (loaded || !configured()) return;
    loaded = true;
    if (cfg.ga4) w.dataLayer.push({ ga4_measurement_id: cfg.ga4 });
    if (cfg.gtm) {
      w.dataLayer.push({ 'gtm.start': Date.now(), event: 'gtm.js' });
      inject('https://www.googletagmanager.com/gtm.js?id=' + encodeURIComponent(cfg.gtm));
    } else {
      gtag('js', new Date());
      gtag('config', cfg.ga4, { allow_google_signals: false, allow_ad_personalization_signals: false });
      inject('https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(cfg.ga4));
    }
  }
  function clearCookies() {
    var host = w.location.hostname;
    var parts = host.split('.');
    var domains = [''];
    for (var i = 0; i < parts.length - 1; i++) domains.push('; domain=.' + parts.slice(i).join('.'));
    document.cookie.split(';').forEach(function (c) {
      var name = c.split('=')[0].trim();
      if (name === '_ga' || name.indexOf('_ga_') === 0 || name === '_gid' || name.indexOf('_gat') === 0) {
        domains.forEach(function (d) {
          document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/' + d;
        });
      }
    });
  }
  /** GA4-Mess-IDs: konfigurierte ID plus alle, die ein _ga_<ID>-Cookie verraten (GTM). */
  function measurementIds() {
    var ids = cfg.ga4 ? [cfg.ga4] : [];
    document.cookie.split(';').forEach(function (c) {
      var name = c.split('=')[0].trim();
      if (name.indexOf('_ga_') === 0) {
        var id = 'G-' + name.slice(4);
        if (GA4_RE.test(id) && ids.indexOf(id) < 0) ids.push(id);
      }
    });
    return ids;
  }
  function revoke() {
    gtag('consent', 'update', { analytics_storage: 'denied' });
    if (loaded) {
      measurementIds().forEach(function (id) {
        w['ga-disable-' + id] = true;
      });
    }
    clearCookies();
    if (loaded) {
      // Kurz warten, damit die App laufende Schreibvorgaenge abschliesst.
      w.setTimeout(function () {
        w.location.reload();
      }, 300);
    }
  }

  w.linefmAnalytics = {
    /** "granted", "denied" oder "" (noch nicht entschieden). */
    state: function () {
      return read();
    },
    /** IDs aus der Build-Konfiguration; laedt sofort, wenn schon zugestimmt. */
    configure: function (gtmId, ga4Id) {
      cfg.gtm = GTM_RE.test(String(gtmId || '')) ? String(gtmId) : '';
      cfg.ga4 = GA4_RE.test(String(ga4Id || '')) ? String(ga4Id) : '';
      if (configured() && read() === 'granted') {
        gtag('consent', 'update', { analytics_storage: 'granted' });
        load();
      }
      return configured();
    },
    grant: function () {
      write('granted');
      gtag('consent', 'update', { analytics_storage: 'granted' });
      load();
    },
    deny: function () {
      write('denied');
      revoke();
    },
    /** "Speicher loeschen": Entscheidung vergessen, beim naechsten Start neu fragen. */
    reset: function () {
      write('');
      revoke();
    },
  };
})();
