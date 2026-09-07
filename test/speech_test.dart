import 'package:coolschool/audio/speech_service.dart';
import 'package:coolschool/audio/spoken_math.dart';
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
      expect(SpokenMath.prepare('5 − 2 = ?', 'ro'), 'cinci minus doi');
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
      expect(AppLocales.speechTagsFor('fr'), containsAll(['fr-CH', 'fr-FR']));
      expect(AppLocales.speechTagsFor('en-US'), containsAll(['en-GB', 'en-US']));
      expect(AppLocales.speechTagsFor('ro'), contains('ro-RO'));
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
