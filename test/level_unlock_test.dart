import 'dart:io';

import 'package:coolschool/content/models.dart';
import 'package:coolschool/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

ContentPack loadPack(String locale) {
  final file = File('assets/content/packs/addition_$locale.json');
  return ContentPack.fromJsonString(file.readAsStringSync());
}

void main() {
  late ContentPack pack;

  setUp(() {
    pack = loadPack('de');
  });

  test('addition packs expose three levels in every language', () {
    for (final locale in ['de', 'fr', 'en', 'ro']) {
      expect(loadPack(locale).levels, hasLength(3));
    }
    expect(pack.levels.first.unlockAfterStars, 0);
    expect(pack.levels[1].unlockAfterStars, 1);
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

  test('third level needs a star on the second', () {
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
        levelIndex: 9,
        levels: pack.levels,
        starsByLevelId: const {},
      ),
      isFalse,
    );
  });

  test('DE FR EN RO addition packs share stable level ids', () {
    final de = pack.levels.map((level) => level.id).toList();
    expect(loadPack('fr').levels.map((level) => level.id).toList(), de);
    expect(loadPack('en').levels.map((level) => level.id).toList(), de);
    expect(loadPack('ro').levels.map((level) => level.id).toList(), de);
  });
}
