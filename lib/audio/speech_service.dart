import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_locales.dart';
import 'spoken_math.dart';
import 'tts_voices.dart';

abstract class SpeechService {
  Future<void> speak(String text, {required String locale, required bool muted});
  Future<void> stop();
}

class NoopSpeech implements SpeechService {
  const NoopSpeech();

  @override
  Future<void> speak(
    String text, {
    required String locale,
    required bool muted,
  }) async {}

  @override
  Future<void> stop() async {}
}

class FlutterTtsSpeech implements SpeechService {
  FlutterTtsSpeech({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  /// Slightly slower than the engine default so kids can follow.
  static const kidRate = 0.46;

  static double pitchFor(String locale) {
    return AppLocales.normalize(locale) == 'fr' ? 1.0 : 1.03;
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(false);
    await _tts.setVolume(1);
    _ready = true;
  }

  @override
  Future<void> speak(
    String text, {
    required String locale,
    required bool muted,
  }) async {
    if (muted || text.trim().isEmpty) return;
    await _ensureReady();
    await _tts.stop();
    final spoken = SpokenMath.prepare(text, locale);
    if (spoken.isEmpty) return;
    await _applyVoice(locale);
    await _tts.setSpeechRate(kidRate);
    await _tts.setPitch(pitchFor(locale));
    await _tts.speak(spoken);
  }

  Future<void> _applyVoice(String locale) async {
    final lang = AppLocales.normalize(locale);
    var selected = false;
    try {
      final voices = TtsVoicePicker.normalize(await _tts.getVoices);
      final picked = TtsVoicePicker.pick(voices, lang);
      if (picked != null) {
        await _tts.setVoice(picked.toEngineMap());
        selected = true;
      }
    } catch (_) {
      // Missing plugin / empty voice list — fall through to setLanguage.
    }
    if (!selected) {
      await _setLanguageFallback(lang);
    }
  }

  Future<void> _setLanguageFallback(String lang) async {
    for (final tag in AppLocales.speechTagsFor(lang)) {
      try {
        final result = await _tts.setLanguage(tag);
        if (result == 1 || result == true || result == '1') return;
        if (result == null) return;
      } catch (_) {
        continue;
      }
    }
  }

  @override
  Future<void> stop() => _tts.stop();
}
