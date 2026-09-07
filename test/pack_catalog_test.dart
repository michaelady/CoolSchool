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
  test('every topic exists in DE FR EN RO with stable level ids', () {
    for (final topic in AssetPackRepository.topicIds) {
      final ids = <String, List<String>>{};
      for (final locale in AppLocales.codes) {
        final pack = loadPack(topic, locale);
        expect(pack.id, topic);
        expect(pack.locale, locale);
        expect(pack.levels, isNotEmpty);
        ids[locale] = pack.levels.map((level) => level.id).toList();
        for (final level in pack.levels) {
          expect(level.exercises, isNotEmpty);
          for (final exercise in level.exercises) {
            expect(exercise.promptTts, isNotEmpty);
            expect(RegExp(r'\d\s*[+\-−]').hasMatch(exercise.promptTts), isFalse);
          }
        }
      }
      expect(ids['fr'], ids['de']);
      expect(ids['en'], ids['de']);
      expect(ids['ro'], ids['de']);
    }
  });

  test('counting packs carry visible items', () {
    final pack = loadPack('counting', 'de');
    expect(pack.levels.first.exercises.first.kind, ExerciseKind.counting);
    expect(pack.levels.first.exercises.first.items, isNotEmpty);
  });

  test('vocab packs use picture choices', () {
    final pack = loadPack('vocab', 'fr');
    expect(pack.levels.first.exercises.first.kind, ExerciseKind.vocab);
    expect(pack.levels.first.exercises.first.usesPictureChoices, isTrue);
  });
}
