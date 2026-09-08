import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_locales.dart';
import 'spoken_math.dart';
import 'tts_voices.dart';

abstract class SpeechService {
  Future<void> speak(String text, {required String locale, required bool muted});
  Future<void> stop();
  Future<TtsLocaleStatus> prepare(String locale);
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

  @override
  Future<TtsLocaleStatus> prepare(String locale) async {
    final lang = AppLocales.normalize(locale);
    return TtsLocaleStatus(
      locale: lang,
      languageTag: AppLocales.speechTagsFor(lang).first,
      matched: true,
      voicesEnumerated: false,
    );
  }
}

class FlutterTtsSpeech implements SpeechService {
  FlutterTtsSpeech({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;
  final Map<String, TtsLocaleStatus> _status = {};

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
  Future<TtsLocaleStatus> prepare(String locale) async {
    final lang = AppLocales.normalize(locale);
    final cached = _status[lang];
    if (cached != null) return cached;
    await _ensureReady();
    final resolved = await _resolve(lang);
    final status = TtsLocaleStatus(
      locale: lang,
      languageTag: resolved.languageTag,
      voiceName: resolved.voice?.name,
      matched: resolved.matchedVoice,
      voicesEnumerated: resolved.voicesEnumerated,
    );
    _status[lang] = status;
    return status;
  }

  Future<TtsResolveResult> _resolve(String lang) async {
    var voices = const <TtsVoice>[];
    var languages = const <String>[];
    try {
      voices = TtsVoicePicker.normalize(await _tts.getVoices);
    } catch (_) {}
    try {
      languages = TtsVoicePicker.normalizeLanguages(await _tts.getLanguages);
    } catch (_) {}
    return TtsVoicePicker.resolve(
      appLocale: lang,
      voices: voices,
      installedLanguages: languages,
    );
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
    TtsResolveResult resolved;
    try {
      resolved = await _resolve(lang);
    } catch (_) {
      resolved = TtsVoicePicker.resolve(
        appLocale: lang,
        voices: const [],
        installedLanguages: const [],
      );
    }
    _status[lang] = TtsLocaleStatus(
      locale: lang,
      languageTag: resolved.languageTag,
      voiceName: resolved.voice?.name,
      matched: resolved.matchedVoice,
      voicesEnumerated: resolved.voicesEnumerated,
    );

    // Always pin the utterance language first so web SpeechSynthesis does not
    // stay on the browser default (usually en-US).
    await _setLanguageTags(lang, preferred: resolved.languageTag);

    if (resolved.voice != null) {
      try {
        await _tts.setVoice(resolved.voice!.toEngineMap());
      } catch (_) {}
      // Some engines reset lang when a voice is applied — set it again.
      await _setLanguageTags(lang, preferred: resolved.languageTag);
    }
  }

  Future<void> _setLanguageTags(String lang, {required String preferred}) async {
    final tags = <String>[
      preferred,
      ...AppLocales.speechTagsFor(lang),
    ];
    final seen = <String>{};
    for (final tag in tags) {
      final bcp = TtsVoicePicker.toBcp47(tag);
      if (bcp.isEmpty || !seen.add(bcp.toLowerCase())) continue;
      // Never apply an English tag for DE/FR/RO content.
      if (lang != 'en' && bcp.toLowerCase().startsWith('en')) continue;
      try {
        final result = await _tts.setLanguage(bcp);
        if (result == 1 || result == true || result == '1' || result == null) {
          return;
        }
      } catch (_) {
        continue;
      }
    }
  }

  @override
  Future<void> stop() => _tts.stop();
}
