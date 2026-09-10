/**
 * VM check: HTMLAudioElement play()/pause() AbortError races.
 * Run: node test/tts_play_race_test.js
 */
'use strict';

const fs = require('fs');
const path = require('path');

const unhandled = [];
process.on('unhandledRejection', (reason) => {
  unhandled.push(reason);
});

class FakeAudio {
  constructor() {
    this.paused = true;
    this.volume = 1;
    this._src = '';
    this.onended = null;
    this.onerror = null;
    this.playCalls = 0;
    this.pauseCalls = 0;
    this._play = null;
  }

  get src() {
    return this._src;
  }

  set src(value) {
    this._src = value;
    this._abortPlay('The play() request was interrupted by a new load request.');
  }

  play() {
    this.playCalls += 1;
    this.paused = false;
    let resolve;
    let reject;
    const promise = new Promise((res, rej) => {
      resolve = res;
      reject = rej;
    });
    this._play = { resolve, reject, promise };
    return promise;
  }

  pause() {
    this.pauseCalls += 1;
    this.paused = true;
    this._abortPlay('The play() request was interrupted by a call to pause()');
  }

  resolvePlay() {
    if (!this._play) return;
    const { resolve } = this._play;
    this._play = null;
    resolve();
  }

  end() {
    if (typeof this.onended === 'function') this.onended();
  }

  _abortPlay(message) {
    if (!this._play) return;
    const { reject } = this._play;
    this._play = null;
    const err = new Error(message);
    err.name = 'AbortError';
    reject(err);
  }
}

const audio = new FakeAudio();
let urlSeq = 0;

global.document = {
  getElementById(id) {
    return id === 'coolschool-tts' ? audio : null;
  }
};
global.Blob = class Blob {
  constructor(parts, opts) {
    this.parts = parts;
    this.type = opts && opts.type;
  }
};
global.URL = {
  createObjectURL() {
    urlSeq += 1;
    return 'blob:coolschool-tts-' + urlSeq;
  },
  revokeObjectURL() {}
};

function makeWav(samples, sampleRate) {
  const dataSize = samples.length * 2;
  const buf = Buffer.alloc(44 + dataSize);
  buf.write('RIFF', 0);
  buf.writeUInt32LE(36 + dataSize, 4);
  buf.write('WAVE', 8);
  buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(sampleRate, 24);
  buf.writeUInt32LE(sampleRate * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write('data', 36);
  buf.writeUInt32LE(dataSize, 40);
  for (let i = 0; i < samples.length; i++) {
    buf.writeInt16LE(samples[i], 44 + i * 2);
  }
  return new Uint8Array(buf);
}

const rate = 22050;
const raw = new Array(220);
for (let i = 0; i < raw.length; i++) {
  raw[i] = Math.round(12000 * Math.sin((2 * Math.PI * 220 * i) / rate));
}
const wavBytes = makeWav(raw, rate);
const wavDataUrl = 'data:audio/x-wav;base64,' + Buffer.from(wavBytes).toString('base64');

global.meSpeak = {
  isVoiceLoaded() {
    return true;
  },
  loadVoice(_voice, cb) {
    if (cb) cb(true);
  },
  speak(_text, _settings, cb) {
    setTimeout(function () {
      cb(true, 1, wavDataUrl);
    }, 5);
    return 1;
  }
};

const code = fs.readFileSync(
  path.join(__dirname, '../web/tts/coolschool_tts.js'),
  'utf8'
);
eval(code);

const tts = global.CoolSchoolTts;
if (!tts || typeof tts.playWavBytes !== 'function' || typeof tts.catchPlay !== 'function') {
  console.error('CoolSchoolTts play helpers missing');
  process.exit(1);
}

function assert(cond, msg) {
  if (!cond) {
    console.error('FAIL:', msg);
    process.exit(1);
  }
}

function abortError(message) {
  const err = new Error(message || 'The play() request was interrupted by a call to pause()');
  err.name = 'AbortError';
  return err;
}

assert(tts.isAbortError(abortError()), 'isAbortError should match Chrome pause interrupt');
assert(
  tts.isAbortError(abortError('The play() request was interrupted by a new load request.')),
  'isAbortError should match load interrupt'
);
assert(!tts.isAbortError(new Error('play blocked')), 'other errors stay visible');

Promise.resolve()
  .then(function () {
    return tts.catchPlay(Promise.reject(abortError())).then(function () {
      return 'ok';
    });
  })
  .then(function (value) {
    assert(value === 'ok', 'catchPlay must swallow AbortError');
    return tts.catchPlay(Promise.reject(new Error('nope'))).then(
      function () {
        assert(false, 'catchPlay must not swallow non-abort errors');
      },
      function (err) {
        assert(String(err.message) === 'nope', 'catchPlay should rethrow other errors');
      }
    );
  })
  .then(function () {
    const gen = tts.speakGeneration + 1;
    // Force generation by speaking through the public API later; here call
    // playWavBytes with the live token after a dummy speak increment via stop.
    tts.stop();
    const live = tts.speakGeneration;
    assert(live >= gen, 'stop() must bump the generation token');
    const started = tts.playWavBytes(wavBytes, live);
    assert(audio.playCalls >= 1, 'playWavBytes should call play()');
    assert(tts.pendingPlay, 'pending play() promise should be tracked');
    // Mute / second Lire / stop while play() is still pending.
    tts.stop();
    return started;
  })
  .then(function () {
    assert(audio.pauseCalls >= 1, 'stop() should pause the element');
    const spoken = tts.speak('eins plus eins', 'de');
    return new Promise(function (resolve, reject) {
      setTimeout(function () {
        tts.stop();
        spoken.then(resolve, reject);
      }, 20);
    });
  })
  .then(function () {
    // Rapid second Lire + mute-style stop before play() resolves.
    const first = tts.speak('zwei plus zwei', 'de');
    const second = tts.speak('drei plus drei', 'de');
    return new Promise(function (resolve, reject) {
      setTimeout(function () {
        tts.stop();
        Promise.all([first, second]).then(resolve, reject);
      }, 20);
    });
  })
  .then(function () {
    return new Promise(function (resolve) {
      setTimeout(resolve, 20);
    });
  })
  .then(function () {
    assert(unhandled.length === 0, 'unhandled AbortError: ' + unhandled.map(String).join(' | '));
    assert(tts.lastUtterance && tts.lastUtterance.locale === 'de', 'DE pack stay default');
    assert(tts.lastUtterance.packId === 'coolschool-de', 'bundled DE pack id');
    assert(tts.speakSettings('de').utf16 === false, 'utf16 stays off');
    console.log('ok: play/pause AbortError races handled', {
      playCalls: audio.playCalls,
      pauseCalls: audio.pauseCalls,
      generation: tts.speakGeneration
    });
    process.exit(0);
  })
  .catch(function (err) {
    console.error('FAIL:', err);
    if (unhandled.length) console.error('unhandled:', unhandled);
    process.exit(1);
  });
