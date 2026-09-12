/**
 * CoolSchool bundled TTS: one eSpeak voice package per UI language.
 * Never loads the English pack for DE / FR / RO.
 *
 * Plays through #coolschool-tts (same HTMLAudioElement unlock as SFX)
 * so Chrome autoplay policy matches the rest of the app.
 *
 * Playback quality (DE/FR/RO clicks and mid-utterance glitches):
 * - Do **not** enable meSpeak's utf16 flag. This eSpeak build's `-b 4` is
 *   16-bit Unicode, which inserts a pause between letters (~8× longer WAV).
 *   Default `-b 1` auto-detects UTF-8 for é/ä/â.
 * - No Klatt `f2` / echo / breath variants: those presets add pops on
 *   language voices. FR/RO ship a milder female formant profile in the
 *   voice JSON instead (pitch range + formants, flutter 0).
 * - FR/RO speak a bit slower than EN so phonemes land (less machine-gun).
 * - wordgap 0: a 10 ms hard silence between words clicked at each boundary.
 * - One synthesis per utterance (never per word). Stale worker callbacks
 *   are ignored so a second Lire cannot overlap the first WAV.
 * - PCM fade in/out + Blob playback instead of pause+empty load (that pop).
 * - Always await/catch HTMLMediaElement.play(). pause() / src changes while
 *   play() is pending reject with AbortError; handle that so mute, a second
 *   Lire, and stop never throw or pop.
 */
(function (global) {
  'use strict';

  var PACKS = {
    de: { id: 'coolschool-de', voice: 'de', languageTag: 'de-CH' },
    fr: { id: 'coolschool-fr', voice: 'fr', languageTag: 'fr-CH' },
    en: { id: 'coolschool-en', voice: 'en/en', languageTag: 'en-GB' },
    ro: { id: 'coolschool-ro', voice: 'ro', languageTag: 'ro-RO' }
  };

  var FADE_IN_SEC = 0.015;
  var FADE_OUT_SEC = 0.04;
  var PEAK = 0.9;

  var lastUtterance = null;
  var loading = {};
  var speakGeneration = 0;
  var objectUrl = null;
  var fadeTimer = null;
  var fadeEpoch = 0;
  /** In-flight HTMLMediaElement.play() promise; must be caught before pause. */
  var pendingPlay = null;

  function audioEl() {
    return global.document && global.document.getElementById('coolschool-tts');
  }

  function speakSettings(locale) {
    var frRo = locale === 'fr' || locale === 'ro';
    return {
      voice: PACKS[locale] && PACKS[locale].voice,
      // Below 100 so Klatt peaks do not clip into clicks.
      amplitude: 88,
      // Kid-friendly: a little higher than the male default, still calm.
      // FR/RO use the female formant profile in the voice JSON; `-p` stays
      // moderate so it does not stack into squeak or pops.
      pitch: locale === 'fr' ? 56 : locale === 'ro' ? 55 : locale === 'de' ? 54 : 52,
      // FR/RO slower so vowels and ă/â/ș have time. DE a touch slower.
      speed: frRo ? 128 : locale === 'de' ? 145 : 155,
      wordgap: 0,
      // This eSpeak's `-b 4` is UTF-16 and pauses between letters. Stay on
      // default `-b 1` (8-bit / UTF-8 auto) so DE/FR/RO stay ~2s, not ~14s.
      utf16: false,
      // `mime` is the proven export path (data:audio/x-wav;base64,…).
      rawdata: 'mime'
    };
  }

  /**
   * Light punctuation so eSpeak can pick statement vs question tunes.
   * Does not rewrite words (SpokenMath / pack promptTts already do that).
   */
  function prepareUtterance(text, locale) {
    var s = String(text || '').replace(/\s+/g, ' ').trim();
    if (!s) return s;
    if (!/[.?!…]$/.test(s)) {
      if (
        /\?/.test(s) ||
        /^(Combien|Qui|Où|Quel|Quelle|Quels|Quelles|Cât|Câte|Cine|Unde|Ce |Was |Wie |Wer |Wo |What |Who |Where |How )/i.test(s)
      ) {
        s += locale === 'fr' ? ' ?' : '?';
      } else {
        s += '.';
      }
    }
    return s;
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
      var tries = 0;
      var done = false;
      function finish(err) {
        if (done) return;
        done = true;
        if (poll) global.clearInterval(poll);
        if (err) {
          delete loading[locale];
          reject(err);
        } else {
          resolve(pack.id);
        }
      }
      function attempt() {
        if (done) return;
        if (global.meSpeak.isVoiceLoaded(pack.voice)) {
          finish();
          return;
        }
        tries += 1;
        if (tries > 40) {
          finish(new Error('CoolSchoolTts: load ' + pack.voice + ' timeout'));
          return;
        }
        global.meSpeak.loadVoice(pack.voice, function (ok) {
          if (ok || global.meSpeak.isVoiceLoaded(pack.voice)) finish();
        });
      }
      // meSpeak's worker posts `ready` with jobId 0; wait a tick so the
      // first loadVoice callback is not dropped on a cold page.
      global.setTimeout(attempt, 60);
      var poll = global.setInterval(function () {
        if (done) return;
        if (global.meSpeak.isVoiceLoaded(pack.voice)) finish();
        else attempt();
      }, 200);
    });
    return loading[locale];
  }

  function isAbortError(err) {
    if (!err) return false;
    var name = err.name || '';
    var msg = String(err.message || err);
    return (
      name === 'AbortError' ||
      /interrupted by a call to (pause|load)/i.test(msg) ||
      /The play\(\) request was interrupted/i.test(msg)
    );
  }

  function catchPlay(promise) {
    if (!promise || typeof promise.then !== 'function') return Promise.resolve();
    return promise.then(
      function () {},
      function (err) {
        if (isAbortError(err)) return;
        throw err;
      }
    );
  }

  /**
   * Attach a rejection handler *before* pause/src so Chrome does not log
   * "Uncaught (in promise) AbortError: The play() request was interrupted".
   */
  function guardPendingPlay() {
    if (!pendingPlay || typeof pendingPlay.then !== 'function') {
      pendingPlay = null;
      return Promise.resolve();
    }
    var tracked = pendingPlay;
    return catchPlay(tracked).then(
      function () {
        if (pendingPlay === tracked) pendingPlay = null;
      },
      function () {
        if (pendingPlay === tracked) pendingPlay = null;
      }
    );
  }

  function cancelFade() {
    fadeEpoch += 1;
    if (fadeTimer) {
      clearInterval(fadeTimer);
      fadeTimer = null;
    }
  }

  function revokeUrl() {
    if (objectUrl) {
      try { global.URL.revokeObjectURL(objectUrl); } catch (_) {}
      objectUrl = null;
    }
  }

  function pauseNode(node) {
    cancelFade();
    // Catch first — pause() while play() is pending is the AbortError race.
    guardPendingPlay();
    if (!node) return;
    try { node.pause(); } catch (_) {}
    try { node.volume = 1; } catch (_) {}
  }

  function fadeOutThenPause(node, ms) {
    if (!node) {
      guardPendingPlay();
      return;
    }
    cancelFade();
    var from;
    try { from = node.paused ? 0 : node.volume; } catch (_) { from = 1; }
    // play() not started yet: paused is still true — do not fade, just
    // guard+pause so a pending play() rejects into catchPlay, not the console.
    if (!from || node.paused) {
      pauseNode(node);
      return;
    }
    var steps = Math.max(3, Math.round(ms / 16));
    var i = 0;
    var epoch = fadeEpoch;
    fadeTimer = setInterval(function () {
      if (epoch !== fadeEpoch) return;
      i += 1;
      var t = i / steps;
      try { node.volume = Math.max(0, from * (1 - t)); } catch (_) {}
      if (i >= steps) {
        pauseNode(node);
      }
    }, 16);
  }

  function stop() {
    speakGeneration += 1;
    var node = audioEl();
    fadeOutThenPause(node, 28);
    // Do not remove src or call load() — that is a pop. Revoke after pause.
    setTimeout(function () {
      var el = audioEl();
      if (el && el.paused) revokeUrl();
    }, 80);
    return catchPlay(pendingPlay);
  }

  function readFourCC(bytes, offset) {
    return String.fromCharCode(
      bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3]
    );
  }

  function readU16(bytes, offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  function readU32(bytes, offset) {
    return (
      (bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24)) >>>
      0
    );
  }

  function getS16(bytes, offset) {
    var v = bytes[offset] | (bytes[offset + 1] << 8);
    return v > 32767 ? v - 65536 : v;
  }

  function setS16(bytes, offset, sample) {
    var s = Math.max(-32767, Math.min(32767, Math.round(sample)));
    if (s < 0) s += 65536;
    bytes[offset] = s & 0xff;
    bytes[offset + 1] = (s >> 8) & 0xff;
  }

  function cosineRamp(t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return 0.5 - 0.5 * Math.cos(Math.PI * t);
  }

  /**
   * Remove DC, fade the edges, and limit peaks so eSpeak WAV start/end
   * discontinuities do not click through the speaker.
   */
  function smoothWavBytes(input) {
    var bytes = input instanceof Uint8Array ? new Uint8Array(input) : new Uint8Array(input);
    if (bytes.length < 44) return bytes;
    if (readFourCC(bytes, 0) !== 'RIFF' || readFourCC(bytes, 8) !== 'WAVE') return bytes;

    var offset = 12;
    var fmt = null;
    var dataOffset = -1;
    var dataLen = 0;
    while (offset + 8 <= bytes.length) {
      var id = readFourCC(bytes, offset);
      var size = readU32(bytes, offset + 4);
      var next = offset + 8 + size + (size % 2);
      if (id === 'fmt ' && size >= 16) {
        fmt = {
          format: readU16(bytes, offset + 8),
          channels: readU16(bytes, offset + 10),
          sampleRate: readU32(bytes, offset + 12),
          bits: readU16(bytes, offset + 22)
        };
      } else if (id === 'data') {
        dataOffset = offset + 8;
        dataLen = Math.min(size, bytes.length - dataOffset);
        break;
      }
      offset = next;
    }
    if (!fmt || dataOffset < 0) return bytes;
    if (fmt.format !== 1 || fmt.channels < 1) return bytes;
    if (fmt.bits !== 16) return bytes;

    var frame = 2 * fmt.channels;
    var sampleCount = Math.floor(dataLen / frame);
    if (sampleCount < 8) return bytes;

    var fadeIn = Math.min(sampleCount, Math.max(2, Math.round(fmt.sampleRate * FADE_IN_SEC)));
    var fadeOut = Math.min(sampleCount, Math.max(2, Math.round(fmt.sampleRate * FADE_OUT_SEC)));

    var sum = 0;
    var n;
    var c;
    var off;
    for (n = 0; n < sampleCount; n++) {
      off = dataOffset + n * frame;
      for (c = 0; c < fmt.channels; c++) sum += getS16(bytes, off + c * 2);
    }
    var dc = sum / (sampleCount * fmt.channels);

    for (n = 0; n < sampleCount; n++) {
      var env = 1;
      if (n < fadeIn) env *= cosineRamp(n / fadeIn);
      if (n >= sampleCount - fadeOut) {
        env *= cosineRamp((sampleCount - 1 - n) / fadeOut);
      }
      off = dataOffset + n * frame;
      for (c = 0; c < fmt.channels; c++) {
        var s = (getS16(bytes, off + c * 2) - dc) * env * PEAK;
        setS16(bytes, off + c * 2, s);
      }
    }
    return bytes;
  }

  function dataUrlToBytes(dataUrl) {
    var comma = dataUrl.indexOf(',');
    var b64 = comma >= 0 ? dataUrl.slice(comma + 1) : dataUrl;
    var bin = global.atob(b64);
    var bytes = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return bytes;
  }

  function bytesFromMeSpeakStream(stream) {
    if (!stream) return null;
    if (typeof stream === 'string') return dataUrlToBytes(stream);
    if (stream instanceof ArrayBuffer) return new Uint8Array(stream);
    if (stream instanceof Uint8Array) return stream;
    if (Object.prototype.toString.call(stream) === '[object Array]') {
      return Uint8Array.from(stream);
    }
    return null;
  }

  function playWavBytes(bytes, generation) {
    var node = audioEl();
    if (!node) return Promise.reject(new Error('CoolSchoolTts: #coolschool-tts missing'));
    if (generation !== speakGeneration) return Promise.resolve();

    // Catch the previous play() before pause/src — both abort a pending play().
    guardPendingPlay();
    cancelFade();
    pauseNode(node);
    revokeUrl();

    var blob = new Blob([bytes], { type: 'audio/wav' });
    objectUrl = global.URL.createObjectURL(blob);

    return new Promise(function (resolve, reject) {
      var settled = false;
      function finish(err) {
        if (settled) return;
        settled = true;
        cleanup();
        if (err) reject(err);
        else resolve();
      }
      function cleanup() {
        node.onended = null;
        node.onerror = null;
      }
      function stale() {
        return generation !== speakGeneration;
      }
      node.onended = function () {
        if (!stale()) revokeUrl();
        finish();
      };
      node.onerror = function () {
        if (stale()) {
          finish();
          return;
        }
        finish(new Error('CoolSchoolTts: audio element failed'));
      };
      try {
        node.volume = 1;
        node.src = objectUrl;
      } catch (err) {
        finish(err);
        return;
      }
      if (stale()) {
        pauseNode(node);
        finish();
        return;
      }
      var played;
      try {
        played = node.play();
      } catch (err) {
        if (stale() || isAbortError(err)) {
          finish();
          return;
        }
        finish(err);
        return;
      }
      pendingPlay = played && typeof played.then === 'function' ? played : null;
      if (!pendingPlay) return;
      var tracked = pendingPlay;
      tracked.then(
        function () {
          if (pendingPlay === tracked) pendingPlay = null;
          if (stale()) {
            pauseNode(node);
            finish();
          }
        },
        function (err) {
          if (pendingPlay === tracked) pendingPlay = null;
          if (stale() || isAbortError(err)) {
            finish();
            return;
          }
          finish(err || new Error('CoolSchoolTts: play blocked'));
        }
      );
    });
  }

  function synthesize(text, locale) {
    var pack = PACKS[locale];
    if (!pack) return Promise.reject(new Error('CoolSchoolTts: no pack for ' + locale));
    if (!text || !String(text).trim()) {
      return Promise.resolve(new Uint8Array(0));
    }
    var spoken = prepareUtterance(text, locale);
    var settings = speakSettings(locale);
    settings.voice = pack.voice;
    return loadPack(locale).then(function () {
      return new Promise(function (resolve, reject) {
        var settled = false;
        var timer = global.setTimeout(function () {
          if (settled) return;
          settled = true;
          reject(new Error('CoolSchoolTts: synthesize timeout'));
        }, 8000);
        var id = global.meSpeak.speak(spoken, settings, function (success, _id, stream) {
          if (settled) return;
          settled = true;
          global.clearTimeout(timer);
          if (!success) {
            reject(new Error('CoolSchoolTts: synthesize failed'));
            return;
          }
          var raw = bytesFromMeSpeakStream(stream);
          if (!raw || !raw.length) {
            reject(new Error('CoolSchoolTts: empty wav'));
            return;
          }
          resolve(smoothWavBytes(raw));
        });
        if (!id) {
          settled = true;
          global.clearTimeout(timer);
          reject(new Error('CoolSchoolTts: speak id 0'));
        }
      });
    });
  }

  function speak(text, locale) {
    var pack = PACKS[locale];
    if (!pack) return Promise.reject(new Error('CoolSchoolTts: no pack for ' + locale));
    if (!text || !String(text).trim()) return Promise.resolve();

    var spoken = prepareUtterance(text, locale);
    var myGen = (speakGeneration += 1);
    fadeOutThenPause(audioEl(), 24);

    return synthesize(spoken, locale)
      .then(function (bytes) {
        if (myGen !== speakGeneration) return;
        var settings = speakSettings(locale);
        lastUtterance = {
          locale: locale,
          packId: pack.id,
          voiceId: pack.voice,
          languageTag: pack.languageTag,
          engine: 'bundled-espeak',
          text: spoken,
          encoding: 'espeak-auto',
          wordgap: 0,
          speed: settings.speed,
          pitch: settings.pitch,
          voiceProfile: locale === 'fr' || locale === 'ro' ? 'kid-female' : 'default'
        };
        if (!bytes.length) return;
        return playWavBytes(bytes, myGen);
      })
      .then(function () {}, function (err) {
        if (myGen !== speakGeneration || isAbortError(err)) return;
        throw err;
      });
  }

  global.CoolSchoolTts = {
    packs: PACKS,
    loadPack: loadPack,
    speak: speak,
    stop: stop,
    synthesize: synthesize,
    smoothWavBytes: smoothWavBytes,
    speakSettings: speakSettings,
    prepareUtterance: prepareUtterance,
    isAbortError: isAbortError,
    catchPlay: catchPlay,
    playWavBytes: playWavBytes,
    get lastUtterance() { return lastUtterance; },
    get speakGeneration() { return speakGeneration; },
    get pendingPlay() { return pendingPlay; }
  };
})(typeof window !== 'undefined' ? window : globalThis);
