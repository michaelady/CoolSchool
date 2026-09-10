import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_locales.dart';
import 'bundled_tts.dart';
import 'spoken_math.dart';
import 'tts_packs.dart';
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
    final pack = TtsPackCatalog.forLocale(lang);
    return TtsLocaleStatus(
      locale: lang,
      languageTag: pack.languageTag,
      packId: pack.id,
      engine: TtsEngineKind.bundled,
      packAvailable: true,
      matched: true,
      voicesEnumerated: false,
    );
  }
}

class FlutterTtsSpeech implements SpeechService {
  FlutterTtsSpeech({FlutterTts? engine, BundledTts? bundled})
      : _tts = engine ?? FlutterTts(),
        _bundled = bundled ?? BundledTts.instance;

  final FlutterTts _tts;
  final BundledTts _bundled;
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
    if (resolved.usesBundled) {
      try {
        await _bundled.loadPack(resolved.pack);
      } catch (_) {}
    }
    final status = _statusFrom(lang, resolved);
    _status[lang] = status;
    return status;
  }

  Future<TtsPackResolveResult> _resolve(String lang) async {
    var voices = const <TtsVoice>[];
    var languages = const <String>[];
    try {
      voices = TtsVoicePicker.normalize(await _tts.getVoices);
    } catch (_) {}
    try {
      languages = TtsVoicePicker.normalizeLanguages(await _tts.getLanguages);
    } catch (_) {}
    return TtsPackPicker.resolve(
      appLocale: lang,
      voices: voices,
      installedLanguages: languages,
      bundledAvailable: _bundled.isAvailable,
      preferNative: kIsWeb && TtsPackCatalog.preferNative(),
    );
  }

  TtsLocaleStatus _statusFrom(String lang, TtsPackResolveResult resolved) {
    return TtsLocaleStatus(
      locale: lang,
      languageTag: resolved.languageTag,
      voiceName: resolved.usesBundled
          ? resolved.pack.voiceId
          : resolved.systemVoice?.name,
      packId: resolved.pack.id,
      engine: resolved.engine,
      packAvailable: resolved.packAvailable,
      matched: resolved.matchedVoice || resolved.packAvailable,
      voicesEnumerated: resolved.voicesEnumerated,
    );
  }

  @override
  Future<void> speak(
    String text, {
    required String locale,
    required bool muted,
  }) async {
    if (text.trim().isEmpty) return;
    if (muted) {
      await stop();
      return;
    }
    await _ensureReady();
    await stop();
    final spoken = SpokenMath.prepare(text, locale);
    if (spoken.isEmpty) return;

    TtsPackResolveResult resolved;
    try {
      resolved = await _resolve(AppLocales.normalize(locale));
    } catch (_) {
      resolved = TtsPackPicker.resolve(
        appLocale: locale,
        voices: const [],
        installedLanguages: const [],
        bundledAvailable: _bundled.isAvailable,
        preferNative: kIsWeb && TtsPackCatalog.preferNative(),
      );
    }
    _status[resolved.pack.locale] = _statusFrom(resolved.pack.locale, resolved);

    if (resolved.usesBundled) {
      try {
        await _bundled.speak(spoken, resolved.pack);
        return;
      } catch (error) {
        debugPrint('CoolSchool bundled TTS failed: $error');
        // Fall through only when a *matching* system voice exists.
        // Never hand DE/FR/RO to an English browser voice.
        if (resolved.systemVoice == null) return;
      }
    }

    await _speakSystem(spoken, resolved);
  }

  Future<void> _speakSystem(String spoken, TtsPackResolveResult resolved) async {
    await _applyVoice(resolved);
    await _tts.setSpeechRate(kidRate);
    await _tts.setPitch(pitchFor(resolved.pack.locale));
    await _tts.speak(spoken);
  }

  Future<void> _applyVoice(TtsPackResolveResult resolved) async {
    final lang = resolved.pack.locale;
    // Always pin the utterance language first so web SpeechSynthesis does not
    // stay on the browser default (usually en-US).
    await _setLanguageTags(lang, preferred: resolved.languageTag);

    if (resolved.systemVoice != null) {
      try {
        await _tts.setVoice(resolved.systemVoice!.toEngineMap());
      } catch (_) {}
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
  Future<void> stop() async {
    await _bundled.stop();
    await _tts.stop();
  }
}
