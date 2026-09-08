import '../l10n/app_locales.dart';

class TtsVoice {
  const TtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  Map<String, String> toEngineMap() => {'name': name, 'locale': locale};

  factory TtsVoice.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final name = '${raw['name'] ?? raw['voiceName'] ?? raw['voiceURI'] ?? ''}';
      final locale = '${raw['locale'] ?? raw['lang'] ?? raw['localeId'] ?? ''}';
      return TtsVoice(name: name.trim(), locale: locale.trim());
    }
    return const TtsVoice(name: '', locale: '');
  }
}

/// Result of picking a BCP-47 language tag and an installed voice.
class TtsResolveResult {
  const TtsResolveResult({
    required this.languageTag,
    required this.fallbackTags,
    this.voice,
    required this.matchedVoice,
    required this.voicesEnumerated,
  });

  /// Tag to pass to flutter_tts / Web Speech (`fr-FR`, `de-CH`, …).
  final String languageTag;

  /// Remaining documented fallbacks after [languageTag].
  final List<String> fallbackTags;

  final TtsVoice? voice;
  final bool matchedVoice;

  /// False when the engine returned an empty voice list (web often does this
  /// before `voiceschanged`). Do not show a "missing voice" hint then.
  final bool voicesEnumerated;

  bool get shouldHint => voicesEnumerated && !matchedVoice;
}

/// Picks a higher-quality installed voice for the app locale.
class TtsVoicePicker {
  const TtsVoicePicker._();

  static String toBcp47(String raw) => raw.trim().replaceAll('_', '-');

  static List<String> normalizeLanguages(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => toBcp47('$item'))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<TtsVoice> normalize(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(TtsVoice.fromDynamic)
        .where((voice) => voice.name.isNotEmpty || voice.locale.isNotEmpty)
        .toList(growable: false);
  }

  static bool languageMatches(String voiceOrLang, String tag) {
    final locale = toBcp47(voiceOrLang).toLowerCase();
    final wanted = toBcp47(tag).toLowerCase();
    if (locale.isEmpty || wanted.isEmpty) return false;
    if (locale == wanted) return true;
    if (locale.startsWith('$wanted-') || wanted.startsWith('$locale-')) {
      return true;
    }
    return locale.split('-').first == wanted.split('-').first;
  }

  static TtsVoice? pick(List<TtsVoice> voices, String appLocale) {
    if (voices.isEmpty) return null;
    final candidates = AppLocales.speechTagsFor(appLocale);
    TtsVoice? best;
    var bestScore = -1;
    for (final voice in voices) {
      final score = _score(voice, candidates);
      if (score > bestScore) {
        bestScore = score;
        best = voice;
      }
    }
    if (bestScore <= 0) return null;
    return best;
  }

  /// Choose a real BCP-47 tag + matching voice. Never returns an English voice
  /// for DE/FR/RO, and never substitutes `en-US` as the language tag.
  static TtsResolveResult resolve({
    required String appLocale,
    required List<TtsVoice> voices,
    List<String> installedLanguages = const [],
  }) {
    final tags = AppLocales.speechTagsFor(appLocale);
    final voice = pick(voices, appLocale);
    var languageTag = tags.first;
    if (voice != null && voice.locale.trim().isNotEmpty) {
      languageTag = toBcp47(voice.locale);
    } else {
      outer:
      for (final tag in tags) {
        for (final lang in installedLanguages) {
          if (languageMatches(lang, tag)) {
            languageTag = toBcp47(lang);
            break outer;
          }
        }
      }
    }
    final fallbacks = tags.where((tag) => toBcp47(tag).toLowerCase() != languageTag.toLowerCase()).toList();
    return TtsResolveResult(
      languageTag: languageTag,
      fallbackTags: fallbacks,
      voice: voice,
      matchedVoice: voice != null,
      voicesEnumerated: voices.isNotEmpty,
    );
  }

  static int _score(TtsVoice voice, List<String> candidates) {
    final locale = toBcp47(voice.locale);
    if (locale.isEmpty) return 0;
    final localeLower = locale.toLowerCase();
    var localeScore = 0;
    for (var i = 0; i < candidates.length; i++) {
      final tag = candidates[i].toLowerCase();
      if (localeLower == tag) {
        localeScore = 120 - i * 8;
        break;
      }
      if (localeLower.startsWith('$tag-') || tag.startsWith('$localeLower-')) {
        localeScore = 90 - i * 8;
        break;
      }
      final voiceLang = localeLower.split('-').first;
      final tagLang = tag.split('-').first;
      if (voiceLang == tagLang) {
        localeScore = 55 - i * 4;
        break;
      }
    }
    if (localeScore <= 0) return 0;
    return localeScore + qualityBonus(voice.name);
  }

  static int qualityBonus(String name) {
    final n = name.toLowerCase();
    var score = 0;
    if (n.contains('google')) score += 50;
    if (n.contains('wavenet') || n.contains('neural')) score += 40;
    if (n.contains('enhanced') || n.contains('premium') || n.contains('natural')) {
      score += 28;
    }
    if (n.contains('microsoft') || n.contains('apple')) score += 12;
    if (n.contains('compact') || n.contains('eloquence') || n.contains('espeak')) {
      score -= 25;
    }
    return score;
  }
}

class TtsLocaleStatus {
  const TtsLocaleStatus({
    required this.locale,
    required this.languageTag,
    this.voiceName,
    required this.matched,
    required this.voicesEnumerated,
  });

  final String locale;
  final String languageTag;
  final String? voiceName;
  final bool matched;
  final bool voicesEnumerated;

  bool get shouldHint => voicesEnumerated && !matched;
}
