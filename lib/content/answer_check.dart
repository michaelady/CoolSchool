/// Kid-friendly answer matching for typed responses.
///
/// Trims, collapses spaces, ignores case, and (when fair) folds accents so
/// `ecole` matches `école` and `scoala` matches `școală`.
class AnswerCheck {
  const AnswerCheck._();

  static const _fold = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ā': 'a',
    'ă': 'a',
    'ą': 'a',
    'ç': 'c',
    'ć': 'c',
    'č': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ē': 'e',
    'ė': 'e',
    'ę': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ī': 'i',
    'į': 'i',
    'ł': 'l',
    'ñ': 'n',
    'ń': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ø': 'o',
    'ō': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ū': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ž': 'z',
    'ź': 'z',
    'ż': 'z',
    'ș': 's',
    'ş': 's',
    'š': 's',
    'ț': 't',
    'ţ': 't',
    'ß': 'ss',
    'æ': 'ae',
    'œ': 'oe',
  };

  static String normalize(String raw) {
    final collapsed = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final buffer = StringBuffer();
    for (final unit in collapsed.runes) {
      final ch = String.fromCharCode(unit);
      buffer.write(_fold[ch] ?? ch);
    }
    return buffer.toString();
  }

  static bool matches(String typed, Iterable<String> accepted) {
    final got = normalize(typed);
    if (got.isEmpty) return false;
    for (final answer in accepted) {
      if (got == normalize(answer)) return true;
    }
    return false;
  }
}
