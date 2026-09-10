/**
 * CoolSchool bundled TTS: one eSpeak voice package per UI language.
 * Never loads the English pack for DE / FR / RO.
 *
 * Plays through #coolschool-tts (same HTMLAudioElement unlock as SFX)
 * so Chrome autoplay policy matches the rest of the app.
 */
(function (global) {
  'use strict';

  var PACKS = {
    de: { id: 'coolschool-de', voice: 'de', languageTag: 'de-CH' },
    fr: { id: 'coolschool-fr', voice: 'fr', languageTag: 'fr-CH' },
    en: { id: 'coolschool-en', voice: 'en/en', languageTag: 'en-GB' },
    ro: { id: 'coolschool-ro', voice: 'ro', languageTag: 'ro-RO' }
  };

  var lastUtterance = null;
  var loading = {};

  function audioEl() {
    return global.document && global.document.getElementById('coolschool-tts');
  }

  function loadPack(locale) {
    var pack = PACKS[locale];
    if (!pack) {
      return Promise.reject(new Error('CoolSchoolTts: no pack for ' + locale));
    }
    if (locale !== 'en' && String(pack.voice).indexOf('en') === 0) {
      return Promise.reject(new Error('CoolSchoolTts: refused English voice for ' + locale));
    }
    if (!global.meSpeak) {
      return Promise.reject(new Error('CoolSchoolTts: meSpeak missing'));
    }
    if (global.meSpeak.isVoiceLoaded(pack.voice)) {
      return Promise.resolve(pack.id);
    }
    if (loading[locale]) return loading[locale];
    loading[locale] = new Promise(function (resolve, reject) {
      global.meSpeak.loadVoice(pack.voice, function (ok, info) {
        if (ok) resolve(pack.id);
        else reject(new Error('CoolSchoolTts: load ' + pack.voice + ' failed: ' + info));
      });
    });
    return loading[locale];
  }

  function stop() {
    var node = audioEl();
    if (node) {
      try {
        node.pause();
        node.removeAttribute('src');
        node.load();
      } catch (_) {}
    }
    if (global.meSpeak) {
      try { global.meSpeak.stop(); } catch (_) {}
    }
  }

  function playDataUrl(dataUrl) {
    var node = audioEl();
    if (!node) return Promise.reject(new Error('CoolSchoolTts: #coolschool-tts missing'));
    return new Promise(function (resolve, reject) {
      function cleanup() {
        node.onended = null;
        node.onerror = null;
      }
      node.onended = function () { cleanup(); resolve(); };
      node.onerror = function () {
        cleanup();
        reject(new Error('CoolSchoolTts: audio element failed'));
      };
      node.src = dataUrl;
      var played = node.play();
      if (played && played.then) {
        played.then(function () {}).catch(function (err) {
          cleanup();
          reject(err || new Error('CoolSchoolTts: play blocked'));
        });
      }
    });
  }

  function speak(text, locale) {
    var pack = PACKS[locale];
    if (!pack) return Promise.reject(new Error('CoolSchoolTts: no pack for ' + locale));
    if (!text || !String(text).trim()) return Promise.resolve();
    return loadPack(locale).then(function () {
      stop();
      lastUtterance = {
        locale: locale,
        packId: pack.id,
        voiceId: pack.voice,
        languageTag: pack.languageTag,
        engine: 'bundled-espeak',
        text: String(text)
      };
      return new Promise(function (resolve, reject) {
        var id = global.meSpeak.speak(String(text), {
          voice: pack.voice,
          amplitude: 100,
          pitch: locale === 'fr' ? 52 : 56,
          speed: 145,
          wordgap: 1,
          variant: 'f2',
          rawdata: 'mime'
        }, function (success, _id, stream) {
          if (!success || !stream) {
            reject(new Error('CoolSchoolTts: synthesize failed'));
            return;
          }
          playDataUrl(stream).then(resolve).catch(reject);
        });
        if (!id) reject(new Error('CoolSchoolTts: speak id 0'));
      });
    });
  }

  global.CoolSchoolTts = {
    packs: PACKS,
    loadPack: loadPack,
    speak: speak,
    stop: stop,
    get lastUtterance() { return lastUtterance; }
  };
})(window);
