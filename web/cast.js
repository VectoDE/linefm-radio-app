// Google Cast (Chromecast) in the web version.
//
// Rule: without consent nothing is requested from Google.
//  - On page load this file only defines window.linefmCast. No network access.
//  - The app (Dart, lib/services/cast/browser_cast*.dart) asks for consent first.
//    Only after grant() may load() inject Google's Cast sender script
//    (www.gstatic.com), which in turn loads the Cast framework from gstatic.
//  - The decision lives in localStorage under KEY ("granted" | "denied"); storing
//    the decision itself is strictly necessary (section 25(2) TDDDG).
//  - deny()/reset() after the script was loaded reload the page, because a loaded
//    script cannot be unloaded.
// API names follow developers.google.com/cast/docs/web_sender and its reference
// (CastContext, CastSession, chrome.cast.media.*).
(function () {
  'use strict';
  var KEY = 'linefm.googleCast';
  var SRC = 'https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1';
  var w = window;
  var loading = null;
  var injected = false;
  var listeners = [];

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
      /* private mode: decision only lasts for this session */
    }
  }
  function ctx() {
    try {
      return w.cast && w.cast.framework ? w.cast.framework.CastContext.getInstance() : null;
    } catch (e) {
      return null;
    }
  }
  function session() {
    var c = ctx();
    return c ? c.getCurrentSession() : null;
  }
  function notify() {
    for (var i = 0; i < listeners.length; i++) {
      try {
        listeners[i]();
      } catch (e) {
        /* listener errors must not break the SDK callback */
      }
    }
  }
  // Cast only works in Chromium browsers (Chrome, Edge) on desktop and Android.
  function supported() {
    var ua = (w.navigator && w.navigator.userAgent) || '';
    if (/iPhone|iPad|iPod/.test(ua)) return false;
    return !!w.chrome;
  }
  function init() {
    var c = ctx();
    if (!c) return false;
    c.setOptions({
      receiverApplicationId: w.chrome.cast.media.DEFAULT_MEDIA_RECEIVER_APP_ID,
      autoJoinPolicy: w.chrome.cast.AutoJoinPolicy.ORIGIN_SCOPED,
    });
    var types = w.cast.framework.CastContextEventType;
    c.addEventListener(types.CAST_STATE_CHANGED, notify);
    c.addEventListener(types.SESSION_STATE_CHANGED, notify);
    return true;
  }
  function load() {
    if (read() !== 'granted' || !supported()) return Promise.resolve(false);
    if (loading) return loading;
    loading = new Promise(function (resolve) {
      w.__onGCastApiAvailable = function (isAvailable) {
        var ok = false;
        try {
          ok = !!isAvailable && init();
        } catch (e) {
          ok = false;
        }
        resolve(ok);
      };
      var s = document.createElement('script');
      s.async = true;
      s.src = SRC;
      s.onerror = function () {
        resolve(false);
      };
      injected = true;
      document.head.appendChild(s);
    });
    return loading;
  }
  function revoke(v) {
    write(v);
    if (injected) {
      try {
        var c = ctx();
        if (c) c.endCurrentSession(true);
      } catch (e) {
        /* ignore */
      }
      w.location.reload();
    }
  }

  w.linefmCast = {
    supported: supported,
    state: read,
    grant: function () {
      write('granted');
    },
    deny: function () {
      revoke('denied');
    },
    reset: function () {
      revoke('');
    },
    load: load,
    onChange: function (fn) {
      listeners.push(fn);
    },
    // NO_DEVICES_AVAILABLE | NOT_CONNECTED | CONNECTING | CONNECTED, '' before load.
    castState: function () {
      var c = ctx();
      return c ? String(c.getCastState()) : '';
    },
    deviceId: function () {
      var s = session();
      var d = s ? s.getCastDevice() : null;
      return d ? String(d.label || '') : '';
    },
    deviceName: function () {
      var s = session();
      var d = s ? s.getCastDevice() : null;
      if (!d) return '';
      try {
        return decodeURIComponent(d.friendlyName || '');
      } catch (e) {
        return String(d.friendlyName || '');
      }
    },
    // Opens the browser's device picker. Resolves true when a session started.
    requestSession: function () {
      var c = ctx();
      if (!c) return Promise.resolve(false);
      return c.requestSession().then(
        function (err) {
          return !err;
        },
        function () {
          return false;
        },
      );
    },
    endSession: function () {
      var c = ctx();
      if (c) c.endCurrentSession(true);
    },
    loadMedia: function (url, contentType, title, artist, album, image) {
      var s = session();
      if (!s) return Promise.resolve(false);
      var m = w.chrome.cast.media;
      var meta = new m.MusicTrackMediaMetadata();
      meta.title = title;
      meta.artist = artist;
      meta.albumName = album;
      if (image) meta.images = [new w.chrome.cast.Image(image)];
      var info = new m.MediaInfo(url, contentType);
      info.streamType = m.StreamType.LIVE;
      info.metadata = meta;
      var req = new m.LoadRequest(info);
      return s.loadMedia(req).then(
        function (err) {
          return !err;
        },
        function () {
          return false;
        },
      );
    },
    stopMedia: function () {
      var s = session();
      var media = s ? s.getMediaSession() : null;
      if (!media) return Promise.resolve();
      return new Promise(function (resolve) {
        media.stop(new w.chrome.cast.media.StopRequest(), resolve, function () {
          resolve();
        });
      });
    },
    setVolume: function (v) {
      var s = session();
      if (s) s.setVolume(v);
    },
  };
})();
