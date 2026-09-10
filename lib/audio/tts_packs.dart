import '../l10n/app_locales.dart';
import 'tts_voices.dart';

/// Dedicated pronunciation package for one UI language.
///
/// Each pack owns that language’s phoneme rules. The English pack is never
/// selected for DE / FR / RO, even when the browser only lists English voices.
class TtsLanguagePack {
  const TtsLanguagePack({
    required this.locale,
    required this.id,
    required this.voiceId,
    required this.languageTag,
    required this.voiceFile,
  });

  /// App language (`de`, `fr`, `en`, `ro`).
  final String locale;

  /// Stable pack id (`coolschool-fr`).
  final String id;

  /// Engine voice id inside the bundled synthesizer (`fr`, `en/en`, …).
  final String voiceId;

  /// BCP-47 tag advertised with this pack.
  final String languageTag;

  /// Voice JSON path relative to `web/tts/` (`voices/fr.json`).
  final String voiceFile;

  bool get isEnglish => locale == 'en';

  /// True when this pack’s voice id is English (must only happen for `en`).
  bool get voiceIdIsEnglish {
    final voice = voiceId.toLowerCase();
    return voice == 'en' || voice.startsWith('en/') || voice.startsWith('en-');
  }
}

/// Four shipped pronunciation packs — one per UI chip.
class TtsPackCatalog {
  const TtsPackCatalog._();

  static const packs = <String, TtsLanguagePack>{
    'de': TtsLanguagePack(
      locale: 'de',
      id: 'coolschool-de',
      voiceId: 'de',
      languageTag: 'de-CH',
      voiceFile: 'voices/de.json',
    ),
    'fr': TtsLanguagePack(
      locale: 'fr',
      id: 'coolschool-fr',
      voiceId: 'fr',
      languageTag: 'fr-CH',
      voiceFile: 'voices/fr.json',
    ),
    'en': TtsLanguagePack(
      locale: 'en',
      id: 'coolschool-en',
      voiceId: 'en/en',
      languageTag: 'en-GB',
      voiceFile: 'voices/en/en.json',
    ),
    'ro': TtsLanguagePack(
      locale: 'ro',
      id: 'coolschool-ro',
      voiceId: 'ro',
      languageTag: 'ro-RO',
      voiceFile: 'voices/ro.json',
    ),
  };

  static TtsLanguagePack forLocale(String locale) {
    return packs[AppLocales.normalize(locale)]!;
  }

  /// `?tts=system` opts into a matching OS/browser voice. Default is the
  /// shipped eSpeak pack for every UI language.
  static bool preferNative({Uri? page}) {
    final uri = page ?? Uri.base;
    return uri.queryParameters['tts'] == 'system';
  }
}

/// Locale → pack + engine. Shipped packs are the default whenever they are
/// available. System English is never used for DE / FR / RO when a native
/// voice or the shipped pack exists.
class TtsPackPicker {
  const TtsPackPicker._();

  static TtsPackResolveResult resolve({
    required String appLocale,
    required List<TtsVoice> voices,
    List<String> installedLanguages = const [],
    bool bundledAvailable = true,
    bool preferNative = false,
  }) {
    final lang = AppLocales.normalize(appLocale);
    final pack = TtsPackCatalog.forLocale(lang);
    if (lang != 'en' && pack.isEnglish) {
      throw StateError('English pack selected for $lang');
    }
    if (lang != 'en' && pack.voiceIdIsEnglish) {
      throw StateError('English voice id on pack ${pack.id}');
    }

    final system = TtsVoicePicker.resolve(
      appLocale: lang,
      voices: voices,
      installedLanguages: installedLanguages,
    );

    final useBundled =
        bundledAvailable && !(preferNative && system.matchedVoice);

    return TtsPackResolveResult(
      pack: pack,
      engine: useBundled ? TtsEngineKind.bundled : TtsEngineKind.system,
      systemVoice: system.voice,
      languageTag: useBundled
          ? pack.languageTag
          : (system.matchedVoice ? system.languageTag : pack.languageTag),
      matchedVoice: system.matchedVoice,
      packAvailable: bundledAvailable,
      voicesEnumerated: system.voicesEnumerated,
    );
  }
}

class TtsPackResolveResult {
  const TtsPackResolveResult({
    required this.pack,
    required this.engine,
    required this.systemVoice,
    required this.languageTag,
    required this.matchedVoice,
    required this.packAvailable,
    required this.voicesEnumerated,
  });

  final TtsLanguagePack pack;
  final TtsEngineKind engine;
  final TtsVoice? systemVoice;
  final String languageTag;
  final bool matchedVoice;
  final bool packAvailable;
  final bool voicesEnumerated;

  /// Hint only when there is no matching system voice *and* no pack engine
  /// (typical Android without a language pack). Web always has packs.
  bool get shouldHint => voicesEnumerated && !matchedVoice && !packAvailable;

  bool get usesBundled => engine == TtsEngineKind.bundled && packAvailable;
}
