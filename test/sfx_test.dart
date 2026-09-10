import 'dart:io';

import 'package:coolschool/audio/sfx_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transition and next wavs are bundled with the other cues', () async {
    for (final name in sfxNames) {
      final data = await rootBundle.load('assets/sounds/$name.wav');
      expect(data.lengthInBytes, greaterThan(2000), reason: '$name.wav missing or tiny');
    }
  });

  test('web sound URLs use the Flutter web assets/assets nest', () {
    expect(
      webSoundUrl('transition', page: Uri.parse('https://michaelady.github.io/CoolSchool/')),
      'https://michaelady.github.io/CoolSchool/assets/assets/sounds/transition.wav',
    );
    expect(
      webSoundUrl('next', page: Uri.parse('https://michaelady.github.io/CoolSchool/?v=p2')),
      'https://michaelady.github.io/CoolSchool/assets/assets/sounds/next.wav',
    );
    expect(
      webSoundUrl('correct', page: Uri.parse('http://localhost:8080/')),
      'http://localhost:8080/assets/assets/sounds/correct.wav',
    );
    expect(webSoundUrl('next', page: Uri.parse('https://example.test/app/?v=p2')), isNot(contains('?')));
  });

  test('index.html ships whoosh audio tags', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('coolschool-sfx-transition'));
    expect(html, contains('assets/assets/sounds/transition.wav'));
    expect(html, contains('coolschool-sfx-next'));
    expect(html, isNot(contains('coolschool-locale-ro')));
  });

  test('index.html ships the bundled TTS engine and per-language packs', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('tts/mespeak.js'));
    expect(html, contains('tts/coolschool_tts.js'));
    expect(html, contains('id="coolschool-tts"'));
    expect(File('web/tts/mespeak.js').existsSync(), isTrue);
    expect(File('web/tts/mespeak-core.js').existsSync(), isTrue);
    expect(File('web/tts/coolschool_tts.js').existsSync(), isTrue);
    for (final name in ['de', 'fr', 'ro']) {
      final json = File('web/tts/voices/$name.json').readAsStringSync();
      expect(json, contains('"voice_id":"$name"'));
      expect(json, isNot(contains('"voice_id":"en')));
    }
    final en = File('web/tts/voices/en/en.json').readAsStringSync();
    expect(en, contains('"voice_id":"en/en"'));
  });

  test('index.html unlocks audio muted so the empty TTS tag does not click', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('a.muted = true'));
    expect(html, contains('#coolschool-tts'));
  });

  test('bundled TTS JS keeps packs default and smooths DE/FR/RO playback', () {
    final js = File('web/tts/coolschool_tts.js').readAsStringSync();
    expect(js, contains("id: 'coolschool-de'"));
    expect(js, contains("id: 'coolschool-fr'"));
    expect(js, contains("id: 'coolschool-en'"));
    expect(js, contains("id: 'coolschool-ro'"));
    expect(js, contains('utf16: false'));
    expect(js, contains('wordgap: 0'));
    expect(js, contains('smoothWavBytes'));
    expect(js, contains('speakGeneration'));
    expect(js, contains('createObjectURL'));
    expect(js, contains('pendingPlay'));
    expect(js, contains('isAbortError'));
    expect(js, contains('catchPlay'));
    expect(js, contains('guardPendingPlay'));
    expect(js, isNot(contains('utf16: true')));
    expect(js, isNot(contains("variant: 'f2'")));
    expect(js, isNot(contains("variant: \"f2\"")));
    expect(js, isNot(contains("removeAttribute('src')")));
    expect(js, contains('amplitude: 88'));
  });

  test('smoothWavBytes fades PCM edges so a square jump does not click', () async {
    final result = await Process.run('node', ['test/tts_wav_smooth_test.js']);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('play() AbortError from pause/stop/second Lire is caught', () async {
    final result = await Process.run('node', ['test/tts_play_race_test.js']);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
