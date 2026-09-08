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
            if (exercise.isType) {
              typed += 1;
              expect(exercise.acceptedAnswers, isNotEmpty);
            } else {
              expect(exercise.choices.length, greaterThanOrEqualTo(2));
            }
          }
        }
        expect(typed, greaterThan(0), reason: '$topic/$locale needs typing exercises');
        final early = [
          ...pack.levels[0].exercises,
          ...pack.levels[1].exercises,
        ];
        expect(
          early.any((item) => item.isType),
          isTrue,
          reason: '$topic/$locale needs a type exercise in L1 or L2',
        );
      }
      expect(ids['fr'], ids['de']);
      expect(ids['en'], ids['de']);
      expect(ids['ro'], ids['de']);
    }
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

  test('langues packs keep picture vocab and typing', () {
    final pack = loadPack('langues', 'fr');
    expect(pack.levels.first.exercises.first.kind, ExerciseKind.vocab);
    expect(pack.levels.first.exercises.first.usesPictureChoices, isTrue);
    expect(
      pack.levels.first.exercises.any((item) => item.isType),
      isTrue,
    );
    expect(
      pack.levels[1].exercises.first.isType,
      isTrue,
    );
  });
}
