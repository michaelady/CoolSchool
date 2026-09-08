import '../l10n/app_locales.dart';

/// Turns digit soup such as `2 + 3` into kid-friendly spoken math.
class SpokenMath {
  const SpokenMath._();

  static const _de = {
    0: 'null',
    1: 'eins',
    2: 'zwei',
    3: 'drei',
    4: 'vier',
    5: 'fünf',
    6: 'sechs',
    7: 'sieben',
    8: 'acht',
    9: 'neun',
    10: 'zehn',
    11: 'elf',
    12: 'zwölf',
    13: 'dreizehn',
    14: 'vierzehn',
    15: 'fünfzehn',
    16: 'sechzehn',
    17: 'siebzehn',
    18: 'achtzehn',
    19: 'neunzehn',
    20: 'zwanzig',
  };

  static const _fr = {
    0: 'zéro',
    1: 'un',
    2: 'deux',
    3: 'trois',
    4: 'quatre',
    5: 'cinq',
    6: 'six',
    7: 'sept',
    8: 'huit',
    9: 'neuf',
    10: 'dix',
    11: 'onze',
    12: 'douze',
    13: 'treize',
    14: 'quatorze',
    15: 'quinze',
    16: 'seize',
    17: 'dix-sept',
    18: 'dix-huit',
    19: 'dix-neuf',
    20: 'vingt',
  };

  static const _en = {
    0: 'zero',
    1: 'one',
    2: 'two',
    3: 'three',
    4: 'four',
    5: 'five',
    6: 'six',
    7: 'seven',
    8: 'eight',
    9: 'nine',
    10: 'ten',
    11: 'eleven',
    12: 'twelve',
    13: 'thirteen',
    14: 'fourteen',
    15: 'fifteen',
    16: 'sixteen',
    17: 'seventeen',
    18: 'eighteen',
    19: 'nineteen',
    20: 'twenty',
  };

  static const _ro = {
    0: 'zero',
    1: 'unu',
    2: 'doi',
    3: 'trei',
    4: 'patru',
    5: 'cinci',
    6: 'șase',
    7: 'șapte',
    8: 'opt',
    9: 'nouă',
    10: 'zece',
    11: 'unsprezece',
    12: 'doisprezece',
    13: 'treisprezece',
    14: 'paisprezece',
    15: 'cincisprezece',
    16: 'șaisprezece',
    17: 'șaptesprezece',
    18: 'optsprezece',
    19: 'nouăsprezece',
    20: 'douăzeci',
  };

  static String numberWord(int n, String locale) {
    final lang = AppLocales.normalize(locale);
    if (n < 0 || n > 100) return n.toString();
    return switch (lang) {
      'fr' => _frWord(n),
      'en' => _enWord(n),
      'ro' => _roWord(n),
      _ => _deWord(n),
    };
  }

  static String _deWord(int n) {
    if (_de.containsKey(n)) return _de[n]!;
    if (n == 100) return 'hundert';
    const tens = {
      2: 'zwanzig',
      3: 'dreißig',
      4: 'vierzig',
      5: 'fünfzig',
      6: 'sechzig',
      7: 'siebzig',
      8: 'achtzig',
      9: 'neunzig',
    };
    final t = n ~/ 10;
    final u = n % 10;
    if (u == 0) return tens[t]!;
    final unit = u == 1 ? 'ein' : _de[u]!;
    return '${unit}und${tens[t]}';
  }

  static String _frWord(int n) {
    if (_fr.containsKey(n)) return _fr[n]!;
    if (n == 100) return 'cent';
    if (n < 70) {
      const tens = {
        2: 'vingt',
        3: 'trente',
        4: 'quarante',
        5: 'cinquante',
        6: 'soixante',
      };
      final t = n ~/ 10;
      final u = n % 10;
      if (u == 0) return tens[t]!;
      if (u == 1) return '${tens[t]}-et-un';
      return '${tens[t]}-${_fr[u]}';
    }
    if (n < 80) {
      if (n == 71) return 'soixante-et-onze';
      return 'soixante-${_fr[n - 60]}';
    }
    if (n == 80) return 'quatre-vingts';
    return 'quatre-vingt-${_fr[n - 80]}';
  }

  static String _enWord(int n) {
    if (_en.containsKey(n)) return _en[n]!;
    if (n == 100) return 'one hundred';
    const tens = {
      2: 'twenty',
      3: 'thirty',
      4: 'forty',
      5: 'fifty',
      6: 'sixty',
      7: 'seventy',
      8: 'eighty',
      9: 'ninety',
    };
    final t = n ~/ 10;
    final u = n % 10;
    if (u == 0) return tens[t]!;
    return '${tens[t]}-${_en[u]}';
  }

  static String _roWord(int n) {
    if (_ro.containsKey(n)) return _ro[n]!;
    if (n == 100) return 'o sută';
    const tens = {
      2: 'douăzeci',
      3: 'treizeci',
      4: 'patruzeci',
      5: 'cincizeci',
      6: 'șaizeci',
      7: 'șaptezeci',
      8: 'optzeci',
      9: 'nouăzeci',
    };
    final t = n ~/ 10;
    final u = n % 10;
    if (u == 0) return tens[t]!;
    return '${tens[t]} și ${_ro[u]}';
  }

  static bool looksLikeDigitSoup(String text) {
    return RegExp(r'\d').hasMatch(text) &&
        RegExp(r'[+\-−×x*=]').hasMatch(text);
  }

  /// Prefer packed [promptTts] when it is already natural language.
  /// Rewrite leftover digits and operators so French is never "2 + 3".
  static String prepare(String text, String locale) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!RegExp(r'\d').hasMatch(trimmed) && !_hasBareOperator(trimmed)) {
      return trimmed;
    }
    return _rewrite(trimmed, AppLocales.normalize(locale));
  }

  static bool _hasBareOperator(String text) {
    return RegExp(r'(^|[\s=])[+\-−×x*](\s|$)').hasMatch(text);
  }

  static String _rewrite(String text, String lang) {
    var out = text;
    out = out.replaceAllMapped(RegExp(r'\d+'), (match) {
      final n = int.tryParse(match.group(0)!);
      if (n == null) return match.group(0)!;
      return numberWord(n, lang);
    });
    const plus = 'plus';
    final minus = switch (lang) {
      'fr' => 'moins',
      'ro' => 'scăzut',
      'en' => 'minus',
      _ => 'minus',
    };
    final times = switch (lang) {
      'fr' => 'fois',
      'en' => 'times',
      'ro' => 'ori',
      _ => 'mal',
    };
    final equals = switch (lang) {
      'fr' => 'égal',
      'en' => 'equals',
      'ro' => 'egal',
      _ => 'ist',
    };
    out = out.replaceAll('×', ' $times ');
    out = out.replaceAllMapped(RegExp(r'(?<=\w|\s)\*(?=\w|\s)'), (_) => ' $times ');
    out = out.replaceAll('+', ' $plus ');
    out = out.replaceAll('−', ' $minus ');
    out = out.replaceAllMapped(RegExp(r'(?<=\w|\s)-(?=\w|\s)'), (_) => ' $minus ');
    // Drop a trailing "= ?" so math prompts become "deux plus trois",
    // but keep a sentence-final "?" ("Combien font deux plus trois ?").
    out = out.replaceAll(RegExp(r'\s*=\s*\??\s*$'), '');
    out = out.replaceAll('=', ' $equals ');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
