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

/// Picks a higher-quality installed voice for the app locale.
class TtsVoicePicker {
  const TtsVoicePicker._();

  static List<TtsVoice> normalize(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(TtsVoice.fromDynamic)
        .where((voice) => voice.name.isNotEmpty || voice.locale.isNotEmpty)
        .toList(growable: false);
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

  static int _score(TtsVoice voice, List<String> candidates) {
    final locale = voice.locale.replaceAll('_', '-');
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
