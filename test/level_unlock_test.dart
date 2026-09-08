import 'dart:io';

import 'package:coolschool/content/models.dart';
import 'package:coolschool/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

ContentPack loadPack(String locale) {
  final file = File('assets/content/packs/math_sciences_$locale.json');
  return ContentPack.fromJsonString(file.readAsStringSync());
}

void main() {
  late ContentPack pack;

  setUp(() {
    pack = loadPack('de');
  });

  test('domain packs expose twenty levels in every language', () {
    for (final locale in ['de', 'fr', 'en', 'ro']) {
      expect(loadPack(locale).levels, hasLength(20));
    }
    expect(pack.levels.first.unlockAfterStars, 0);
    expect(pack.levels[1].unlockAfterStars, 1);
    expect(pack.levels.last.unlockAfterStars, 1);
  });

  test('first level is always unlocked', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 0,
        levels: pack.levels,
        starsByLevelId: const {},
      ),
      isTrue,
    );
  });

  test('second level stays locked until the first has a star', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 1,
        levels: pack.levels,
        starsByLevelId: const {},
      ),
      isFalse,
    );
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 1,
        levels: pack.levels,
        starsByLevelId: {pack.levels.first.id: 1},
      ),
      isTrue,
    );
  });

  test('later levels need a star on the previous level', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 2,
        levels: pack.levels,
        starsByLevelId: {pack.levels.first.id: 3},
      ),
      isFalse,
    );
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 2,
        levels: pack.levels,
        starsByLevelId: {
          pack.levels.first.id: 3,
          pack.levels[1].id: 1,
        },
      ),
      isTrue,
    );
  });

  test('out of range index is locked', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 99,
        levels: pack.levels,
        starsByLevelId: const {},
      ),
      isFalse,
    );
  });

  test('DE FR EN RO math packs share stable level ids', () {
    final de = pack.levels.map((level) => level.id).toList();
    expect(loadPack('fr').levels.map((level) => level.id).toList(), de);
    expect(loadPack('en').levels.map((level) => level.id).toList(), de);
    expect(loadPack('ro').levels.map((level) => level.id).toList(), de);
  });
}
