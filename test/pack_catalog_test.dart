import 'dart:convert';
import 'dart:io';

import 'package:coolschool/content/models.dart';
import 'package:coolschool/content/pack_repository.dart';
import 'package:coolschool/l10n/app_locales.dart';
import 'package:flutter_test/flutter_test.dart';

ContentPack loadPack(String topic, String locale) {
  final file = File('assets/content/packs/${topic}_$locale.json');
  return ContentPack.fromJsonString(file.readAsStringSync());
}

void main() {
  test('catalog is 6 PER domains × 20 difficulties in DE FR EN RO', () {
    expect(AssetPackRepository.topicIds, hasLength(6));
    expect(AssetPackRepository.levelsPerDomain, 20);
    for (final topic in AssetPackRepository.topicIds) {
      final ids = <String, List<String>>{};
      for (final locale in AppLocales.codes) {
        final pack = loadPack(topic, locale);
        expect(pack.id, topic);
        expect(pack.locale, locale);
        expect(pack.levels, hasLength(20));
        expect(pack.lp21.competenceId, isNotEmpty);
        ids[locale] = pack.levels.map((level) => level.id).toList();
        var typed = 0;
        for (var i = 0; i < pack.levels.length; i++) {
          final level = pack.levels[i];
          expect(level.id, '$topic-l${i + 1}');
          expect(level.lp21Tag, isNotEmpty);
          expect(level.exercises, isNotEmpty);
          expect(level.unlockAfterStars, i < 5 ? 0 : 1);
          for (final exercise in level.exercises) {
            expect(exercise.promptTts, isNotEmpty);
            expect(RegExp(r'\d\s*[+\-−]').hasMatch(exercise.promptTts), isFalse);
            expect(
              RegExp(
                r'[\u{1F000}-\u{1FAFF}\u{2190}-\u{21FF}\u{2300}-\u{23FF}\u{25A0}-\u{25FF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{266A}-\u{266F}]',
                unicode: true,
              ).hasMatch(exercise.promptTts),
              isFalse,
              reason: '${pack.id}/$locale ${exercise.id} spoken emoji → ${exercise.promptTts}',
            );
            expect(
              RegExp(
                r'(écoute bien ce mot|hör gut zu, das wort ist|ascultă bine acest cuvânt|listen carefully to this word).{0,8}(schreib|écris|ecris|type|scrie)',
                caseSensitive: false,
              ).hasMatch(exercise.promptTts),
              isFalse,
              reason: '${pack.id}/$locale ${exercise.id} type wrap → ${exercise.promptTts}',
            );
            if (locale != 'en') {
              expect(
                exercise.promptTts.toLowerCase(),
                isNot(contains('listen to this word')),
                reason: '${pack.id}/$locale ${exercise.id} → ${exercise.promptTts}',
              );
              expect(
                exercise.promptTts.toLowerCase(),
                isNot(contains('listen carefully')),
                reason: '${pack.id}/$locale ${exercise.id} → ${exercise.promptTts}',
              );
              expect(
                exercise.promptTts,
                isNot(contains('Type the number')),
                reason: '${pack.id}/$locale ${exercise.id} → ${exercise.promptTts}',
              );
            }
            if (exercise.isType) {
              typed += 1;
              expect(exercise.acceptedAnswers, isNotEmpty);
            } else {
              expect(exercise.choices.length, greaterThanOrEqualTo(2));
            }
          }
        }
        expect(typed, greaterThan(0), reason: '$topic/$locale needs typing exercises');
        expect(
          pack.levels.first.exercises.any((item) => item.isType),
          isTrue,
          reason: '$topic/$locale L1 needs a type exercise (not only later locked levels)',
        );
      }
      expect(ids['fr'], ids['de']);
      expect(ids['en'], ids['de']);
      expect(ids['ro'], ids['de']);
    }
  });

  test('spoken prompts are full kid sentences, not one-word cues', () {
    for (final topic in AssetPackRepository.topicIds) {
      for (final locale in AppLocales.codes) {
        final pack = loadPack(topic, locale);
        for (final level in pack.levels) {
          for (final exercise in level.exercises) {
            final words = exercise.promptTts.trim().split(RegExp(r'\s+')).length;
            expect(
              words,
              greaterThanOrEqualTo(4),
              reason: '${pack.id}/$locale ${exercise.id} → ${exercise.promptTts}',
            );
          }
        }
      }
    }
    final frMath = loadPack('math_sciences', 'fr').levels.first.exercises.first;
    expect(frMath.promptTts, contains('Combien font'));
    expect(frMath.promptTts, contains('Choisis'));
    final roMath = loadPack('math_sciences', 'ro').levels.first.exercises.first;
    expect(roMath.promptTts, contains('Cât fac'));
    expect(roMath.promptTts, contains('Alege'));
    final frType = loadPack('langues', 'fr').levels.first.exercises[1];
    expect(frType.isType, isTrue);
    expect(frType.promptTts.toLowerCase(), contains('mot'));
    final roType = loadPack('shs', 'ro').levels.first.exercises
        .firstWhere((item) => item.isType);
    expect(roType.promptTts.toLowerCase(), contains('cuvântul'));
    final frNumber = loadPack('arts', 'fr').levels[8].exercises[2];
    expect(frNumber.isType, isTrue);
    expect(frNumber.promptTts, contains('Écris le nombre'));
    expect(frNumber.promptTts, contains('plaît'));
    expect(frNumber.promptTts, isNot(contains('Écoute bien ce mot')));
    final deNumber = loadPack('arts', 'de').levels[8].exercises[2];
    expect(deNumber.promptTts, contains('Schreib bitte die Zahl'));
    expect(deNumber.promptTts, isNot(contains('Hör gut zu')));
    final roNumber = loadPack('arts', 'ro').levels[8].exercises[2];
    expect(roNumber.promptTts, contains('Te rog, scrie numărul'));
    expect(roNumber.promptTts, isNot(contains('Ascultă bine acest cuvânt')));
  });

  test('math packs fold counting and spoken subtraction', () {
    final pack = loadPack('math_sciences', 'de');
    expect(pack.levels.first.exercises.first.prompt, '1 + 1 = ?');
    expect(
      pack.levels.first.exercises.any((item) => item.kind == ExerciseKind.counting),
      isTrue,
    );
    final ro = loadPack('math_sciences', 'ro');
    final spokenMinus = ro.levels
        .expand((level) => level.exercises)
        .where((item) => item.promptTts.contains('scăzut'));
    expect(spokenMinus, isNotEmpty);
    for (final exercise in spokenMinus) {
      expect(exercise.promptTts.toLowerCase(), isNot(contains('minus')));
    }
  });

  test('langues packs keep picture vocab and typing on L1', () {
    for (final locale in AppLocales.codes) {
      final pack = loadPack('langues', locale);
      expect(pack.levels.first.exercises.first.kind, ExerciseKind.vocab);
      expect(pack.levels.first.exercises.first.usesPictureChoices, isTrue);
      expect(pack.levels.first.exercises[1].isType, isTrue);
    }
  });

  test('math packs type a count on L1 after the opener', () {
    for (final locale in AppLocales.codes) {
      final pack = loadPack('math_sciences', locale);
      expect(pack.levels.first.exercises.first.isChoice, isTrue);
      expect(pack.levels.first.exercises[1].isType, isTrue);
      expect(pack.levels.first.exercises[1].kind, ExerciseKind.counting);
    }
  });

  test('FR and RO voice JSON keep language dicts with a female formant profile', () {
    for (final locale in ['fr', 'ro']) {
      final raw = jsonDecode(File('web/tts/voices/$locale.json').readAsStringSync()) as Map;
      expect(raw['voice_id'], locale);
      expect((raw['dict'] as String).length, greaterThan(1000));
      final voice = utf8.decode(base64.decode(raw['voice'] as String));
      expect(voice, contains('gender female'));
      expect(voice, contains('language $locale'));
      expect(voice.toLowerCase(), isNot(contains('echo')));
      expect(voice.toLowerCase(), isNot(contains('breath')));
      expect(voice.toLowerCase(), isNot(contains('klatt')));
    }
  });
}
