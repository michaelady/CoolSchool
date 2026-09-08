/// App language codes and BCP-47 speech tags (PER / kid TTS).
class AppLocales {
  const AppLocales._();

  static const codes = ['de', 'fr', 'en', 'ro'];

  static const chips = {'de': 'DE', 'fr': 'FR', 'en': 'EN', 'ro': 'RO'};

  /// Preferred speech tags first, then broader fallbacks.
  static const speechCandidates = <String, List<String>>{
    'de': ['de-CH', 'de-DE', 'de-AT', 'de'],
    'fr': ['fr-CH', 'fr-FR', 'fr-CA', 'fr'],
    'en': ['en-GB', 'en-US', 'en'],
    'ro': ['ro-RO', 'ro'],
  };

  static String normalize(String raw) {
    final code = raw.split(RegExp(r'[-_]')).first.toLowerCase();
    return codes.contains(code) ? code : 'de';
  }

  static List<String> speechTagsFor(String locale) {
    return speechCandidates[normalize(locale)] ?? speechCandidates['de']!;
  }
}
