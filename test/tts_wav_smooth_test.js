/**
 * VM check for CoolSchoolTts.smoothWavBytes + speakSettings.
 * Run: node test/tts_wav_smooth_test.js
 */
'use strict';

const fs = require('fs');
const path = require('path');

const code = fs.readFileSync(
  path.join(__dirname, '../web/tts/coolschool_tts.js'),
  'utf8'
);
eval(code);

const tts = global.CoolSchoolTts;
if (!tts || typeof tts.smoothWavBytes !== 'function') {
  console.error('CoolSchoolTts.smoothWavBytes missing');
  process.exit(1);
}

function assert(cond, msg) {
  if (!cond) {
    console.error('FAIL:', msg);
    process.exit(1);
  }
}

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

function readS16(bytes, offset) {
  const v = bytes[offset] | (bytes[offset + 1] << 8);
  return v > 32767 ? v - 65536 : v;
}

const rate = 22050;
const n = 2205; // 100 ms
const raw = new Array(n);
for (let i = 0; i < n; i++) {
  raw[i] = Math.round(18000 * Math.sin((2 * Math.PI * 220 * i) / rate));
}
raw[0] = 24000;
raw[n - 1] = -24000;
const wav = makeWav(raw, rate);
const out = tts.smoothWavBytes(wav);
const first = Math.abs(readS16(out, 44));
const last = Math.abs(readS16(out, 44 + (n - 1) * 2));
let peak = 0;
for (let i = Math.floor(n * 0.3); i < Math.floor(n * 0.7); i++) {
  peak = Math.max(peak, Math.abs(readS16(out, 44 + i * 2)));
}

assert(first < 800, 'fade-in should bring the first sample near 0, got ' + first);
assert(last < 800, 'fade-out should bring the last sample near 0, got ' + last);
assert(peak > 8000, 'mid-utterance level should stay audible, got ' + peak);

for (const locale of ['de', 'fr', 'en', 'ro']) {
  const pack = tts.packs[locale];
  assert(pack && pack.id === 'coolschool-' + locale, 'pack id ' + locale);
  const s = tts.speakSettings(locale);
  assert(s.utf16 === false, locale + ' must not use eSpeak -b 4 / utf16');
  assert(s.wordgap === 0, locale + ' must not insert hard word gaps');
  assert(s.variant === undefined, locale + ' must not use Klatt f2 echo');
  assert(s.amplitude < 100, locale + ' amplitude must not clip at 100');
  if (locale !== 'en') {
    assert(String(pack.voice).indexOf('en') !== 0, locale + ' must not use English voice');
  }
}

console.log('ok: fade-in', first, 'fade-out', last, 'peak', peak);
process.exit(0);
