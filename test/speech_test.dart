import 'package:coolschool/audio/speech_service.dart';
import 'package:coolschool/audio/spoken_math.dart';
import 'package:coolschool/audio/tts_packs.dart';
import 'package:coolschool/audio/tts_voices.dart';
import 'package:coolschool/l10n/app_locales.dart';
import 'package:coolschool/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpokenMath', () {
    test('keeps natural-language French prompts', () {
      expect(
        SpokenMath.prepare('Combien font deux plus trois ?', 'fr'),
        'Combien font deux plus trois ?',
      );
    });

    test('rewrites digit soup into spoken words', () {
      expect(SpokenMath.prepare('2 + 3 = ?', 'fr'), 'deux plus trois');
      expect(SpokenMath.prepare('2 + 3 = ?', 'de'), 'zwei plus drei');
      expect(SpokenMath.prepare('5 - 2 = ?', 'en'), 'five minus two');
      expect(SpokenMath.prepare('5 − 2 = ?', 'de'), 'fünf minus zwei');
      expect(SpokenMath.prepare('5 − 2 = ?', 'fr'), 'cinq moins deux');
      expect(SpokenMath.prepare('5 − 2 = ?', 'ro'), 'cinci scăzut doi');
    });

    test('rewrites leftover digits inside a sentence', () {
      expect(
        SpokenMath.prepare('Combien font 2 + 3 ?', 'fr'),
        'Combien font deux plus trois ?',
      );
    });

    test('number words cover 1-20', () {
      expect(SpokenMath.numberWord(1, 'fr'), 'un');
      expect(SpokenMath.numberWord(20, 'de'), 'zwanzig');
      expect(SpokenMath.numberWord(12, 'en'), 'twelve');
      expect(SpokenMath.numberWord(8, 'ro'), 'opt');
    });

    test('composes 21-100 without leftover digits', () {
      expect(SpokenMath.numberWord(21, 'de'), 'einundzwanzig');
      expect(SpokenMath.numberWord(25, 'fr'), 'vingt-cinq');
      expect(SpokenMath.numberWord(71, 'fr'), 'soixante-et-onze');
      expect(SpokenMath.numberWord(80, 'fr'), 'quatre-vingts');
      expect(SpokenMath.numberWord(42, 'en'), 'forty-two');
      expect(SpokenMath.numberWord(21, 'ro'), 'douăzeci și unu');
      expect(SpokenMath.prepare('21 + 8 = ?', 'de'), 'einundzwanzig plus acht');
    });
  });

  group('TtsVoicePicker', () {
    test('prefers a higher-quality matching locale voice', () {
      final picked = TtsVoicePicker.pick(
        const [
          TtsVoice(name: 'Samantha', locale: 'en-US'),
          TtsVoice(name: 'Thomas', locale: 'fr-FR'),
          TtsVoice(name: 'Google français', locale: 'fr-FR'),
          TtsVoice(name: 'Google Deutsch', locale: 'de-DE'),
        ],
        'fr',
      );
      expect(picked?.name, 'Google français');
      expect(picked?.locale, 'fr-FR');
    });

    test('prefers Swiss German when present', () {
      final picked = TtsVoicePicker.pick(
        const [
          TtsVoice(name: 'Google Deutsch', locale: 'de-DE'),
          TtsVoice(name: 'Google Deutsch (Schweiz)', locale: 'de-CH'),
        ],
        'de',
      );
      expect(picked?.locale, 'de-CH');
    });

    test('returns null when no voice matches the language', () {
      final picked = TtsVoicePicker.pick(
        const [TtsVoice(name: 'Samantha', locale: 'en-US')],
        'ro',
      );
      expect(picked, isNull);
    });

    test('speech tags are BCP-47 fallbacks', () {
      expect(AppLocales.speechTagsFor('de'), ['de-CH', 'de-DE', 'de-AT', 'de']);
      expect(AppLocales.speechTagsFor('fr'), containsAll(['fr-CH', 'fr-FR']));
      expect(AppLocales.speechTagsFor('en-US'), containsAll(['en-GB', 'en-US']));
      expect(AppLocales.speechTagsFor('ro'), contains('ro-RO'));
    });

    test('resolve never picks an English voice for DE/FR/RO', () {
      const englishOnly = [TtsVoice(name: 'Samantha', locale: 'en-US')];
      for (final locale in ['de', 'fr', 'ro']) {
        final resolved = TtsVoicePicker.resolve(
          appLocale: locale,
          voices: englishOnly,
        );
        expect(resolved.voice, isNull);
        expect(resolved.matchedVoice, isFalse);
        expect(resolved.shouldHint, isTrue);
        expect(resolved.languageTag.toLowerCase().startsWith('en'), isFalse);
        expect(resolved.languageTag, AppLocales.speechTagsFor(locale).first);
      }
    });

    test('resolve prefers an installed matching voice locale as the tag', () {
      final resolved = TtsVoicePicker.resolve(
        appLocale: 'fr',
        voices: const [
          TtsVoice(name: 'Samantha', locale: 'en-US'),
          TtsVoice(name: 'Google français', locale: 'fr_FR'),
        ],
      );
      expect(resolved.matchedVoice, isTrue);
      expect(resolved.voice?.name, 'Google français');
      expect(TtsVoicePicker.toBcp47(resolved.languageTag), 'fr-FR');
      expect(resolved.shouldHint, isFalse);
    });

    test('empty voice list does not show a missing-voice hint', () {
      final resolved = TtsVoicePicker.resolve(
        appLocale: 'de',
        voices: const [],
        installedLanguages: const ['de-CH'],
      );
      expect(resolved.voicesEnumerated, isFalse);
      expect(resolved.shouldHint, isFalse);
      expect(resolved.languageTag, 'de-CH');
    });
  });

  group('TtsPackCatalog', () {
    test('ships one dedicated pack per UI language', () {
      expect(TtsPackCatalog.packs.keys.toSet(), {'de', 'fr', 'en', 'ro'});
      for (final locale in AppLocales.codes) {
        final pack = TtsPackCatalog.forLocale(locale);
        expect(pack.locale, locale);
        expect(pack.id, 'coolschool-$locale');
        expect(pack.languageTag.toLowerCase().startsWith(locale), isTrue);
        expect(pack.voiceFile, contains(locale == 'en' ? 'en/en.json' : '$locale.json'));
      }
    });

    test('non-English packs never point at an English voice id', () {
      for (final locale in ['de', 'fr', 'ro']) {
        final pack = TtsPackCatalog.forLocale(locale);
        expect(pack.isEnglish, isFalse);
        expect(pack.voiceIdIsEnglish, isFalse);
        expect(pack.voiceId.toLowerCase().startsWith('en'), isFalse);
      }
      expect(TtsPackCatalog.forLocale('en').voiceIdIsEnglish, isTrue);
    });

    test('preferNative is the optional tts=system query flag', () {
      expect(TtsPackCatalog.preferNative(page: Uri.parse('https://x.test/CoolSchool/')), isFalse);
      expect(TtsPackCatalog.preferNative(page: Uri.parse('https://x.test/CoolSchool/?tts=pack')), isFalse);
      expect(
        TtsPackCatalog.preferNative(page: Uri.parse('https://x.test/CoolSchool/?tts=system')),
        isTrue,
      );
    });
  });

  group('TtsPackPicker', () {
    test('DE/FR/EN/RO default to shipped packs without a query flag', () {
      const voices = [
        TtsVoice(name: 'Samantha', locale: 'en-US'),
        TtsVoice(name: 'Google français', locale: 'fr-FR'),
        TtsVoice(name: 'Google Deutsch', locale: 'de-DE'),
        TtsVoice(name: 'Google română', locale: 'ro-RO'),
      ];
      for (final locale in AppLocales.codes) {
        final resolved = TtsPackPicker.resolve(
          appLocale: locale,
          voices: voices,
          bundledAvailable: true,
        );
        expect(resolved.engine, TtsEngineKind.bundled, reason: locale);
        expect(resolved.usesBundled, isTrue, reason: locale);
        expect(resolved.pack.id, 'coolschool-$locale');
        expect(resolved.pack.locale, locale);
        if (locale != 'en') {
          expect(resolved.pack.voiceId.toLowerCase().startsWith('en'), isFalse);
        }
      }
    });

    test('English-only browser still selects the native bundled pack', () {
      const englishOnly = [TtsVoice(name: 'Samantha', locale: 'en-US')];
      for (final locale in ['de', 'fr', 'ro']) {
        final resolved = TtsPackPicker.resolve(
          appLocale: locale,
          voices: englishOnly,
          bundledAvailable: true,
        );
        expect(resolved.pack.locale, locale);
        expect(resolved.pack.isEnglish, isFalse);
        expect(resolved.systemVoice, isNull);
        expect(resolved.engine, TtsEngineKind.bundled);
        expect(resolved.usesBundled, isTrue);
        expect(resolved.shouldHint, isFalse);
        expect(resolved.languageTag.toLowerCase().startsWith('en'), isFalse);
        expect(resolved.pack.voiceId.toLowerCase().startsWith('en'), isFalse);
      }
    });

    test('default prefers the shipped pack even if a native system voice exists', () {
      final resolved = TtsPackPicker.resolve(
        appLocale: 'fr',
        voices: const [
          TtsVoice(name: 'Samantha', locale: 'en-US'),
          TtsVoice(name: 'Google français', locale: 'fr-FR'),
        ],
        bundledAvailable: true,
      );
      expect(resolved.pack.locale, 'fr');
      expect(resolved.pack.id, 'coolschool-fr');
      expect(resolved.systemVoice?.name, 'Google français');
      expect(resolved.systemVoice?.locale.toLowerCase().startsWith('en'), isFalse);
      expect(resolved.engine, TtsEngineKind.bundled);
      expect(resolved.usesBundled, isTrue);
      expect(resolved.languageTag, 'fr-CH');
      expect(resolved.matchedVoice, isTrue);
      expect(resolved.shouldHint, isFalse);
    });

    test('never picks an English voice when only the native pack exists', () {
      final resolved = TtsPackPicker.resolve(
        appLocale: 'ro',
        voices: const [
          TtsVoice(name: 'Google US English', locale: 'en-US'),
          TtsVoice(name: 'Google UK English', locale: 'en-GB'),
        ],
        bundledAvailable: true,
      );
      expect(resolved.pack.id, 'coolschool-ro');
      expect(resolved.systemVoice, isNull);
      expect(resolved.engine, TtsEngineKind.bundled);
      expect(TtsVoicePicker.pick(const [
        TtsVoice(name: 'Google US English', locale: 'en-US'),
      ], 'ro'), isNull);
    });

    test('preferNative opts into a matching system voice', () {
      final resolved = TtsPackPicker.resolve(
        appLocale: 'de',
        voices: const [TtsVoice(name: 'Google Deutsch', locale: 'de-DE')],
        bundledAvailable: true,
        preferNative: true,
      );
      expect(resolved.engine, TtsEngineKind.system);
      expect(resolved.pack.locale, 'de');
      expect(resolved.systemVoice?.name, 'Google Deutsch');
      expect(resolved.languageTag, 'de-DE');
    });

    test('preferNative still uses the pack when no native voice matches', () {
      final resolved = TtsPackPicker.resolve(
        appLocale: 'ro',
        voices: const [TtsVoice(name: 'Samantha', locale: 'en-US')],
        bundledAvailable: true,
        preferNative: true,
      );
      expect(resolved.engine, TtsEngineKind.bundled);
      expect(resolved.pack.id, 'coolschool-ro');
      expect(resolved.systemVoice, isNull);
    });

    test('Android without a pack engine still hints when only English voices exist', () {
      final resolved = TtsPackPicker.resolve(
        appLocale: 'fr',
        voices: const [TtsVoice(name: 'Samantha', locale: 'en-US')],
        bundledAvailable: false,
      );
      expect(resolved.pack.locale, 'fr');
      expect(resolved.engine, TtsEngineKind.system);
      expect(resolved.usesBundled, isFalse);
      expect(resolved.shouldHint, isTrue);
    });

    test('English locale defaults to the English pack, native is opt-in', () {
      final bundled = TtsPackPicker.resolve(
        appLocale: 'en',
        voices: const [TtsVoice(name: 'Samantha', locale: 'en-US')],
        bundledAvailable: true,
      );
      expect(bundled.pack.locale, 'en');
      expect(bundled.engine, TtsEngineKind.bundled);
      expect(bundled.pack.voiceId, 'en/en');
      expect(bundled.systemVoice?.name, 'Samantha');

      final system = TtsPackPicker.resolve(
        appLocale: 'en',
        voices: const [TtsVoice(name: 'Samantha', locale: 'en-US')],
        bundledAvailable: true,
        preferNative: true,
      );
      expect(system.engine, TtsEngineKind.system);
      expect(system.systemVoice?.name, 'Samantha');
    });
  });

  group('TtsLocaleStatus', () {
    test('web with a shipped pack does not show the missing-voice hint', () {
      const status = TtsLocaleStatus(
        locale: 'fr',
        languageTag: 'fr-CH',
        packId: 'coolschool-fr',
        engine: TtsEngineKind.bundled,
        packAvailable: true,
        matched: false,
        voicesEnumerated: true,
      );
      expect(status.shouldHint, isFalse);
    });
  });

  group('kid speech settings', () {
    test('uses a slightly slow rate and a calm French pitch', () {
      expect(FlutterTtsSpeech.kidRate, lessThan(0.5));
      expect(FlutterTtsSpeech.pitchFor('fr'), 1.0);
      expect(FlutterTtsSpeech.pitchFor('de'), greaterThan(1.0));
    });
  });

  group('localized feedback hold strings', () {
    test('each language has a distinct correct and wrong banner', () {
      expect(const I18n('de').correct, 'Richtig!');
      expect(const I18n('de').wrong, 'Schade!');
      expect(const I18n('fr').correct, 'Bravo !');
      expect(const I18n('en').correct, 'Right!');
      expect(const I18n('ro').correct, 'Corect!');
      expect(const I18n('ro').wrong, 'Aproape!');
    });
  });
}
