import 'dart:io';

import 'package:coolschool/content/models.dart';
import 'package:coolschool/game/progress_store.dart';
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
    expect(pack.levels[4].unlockAfterStars, 0);
    expect(pack.levels[5].unlockAfterStars, 1);
    expect(pack.levels.last.unlockAfterStars, 1);
  });

  test('first five levels are always unlocked', () {
    for (var i = 0; i < LevelUnlock.freeExploreCount; i++) {
      expect(
        LevelUnlock.isUnlocked(
          levelIndex: i,
          levels: pack.levels,
          starsByLevelId: const {},
        ),
        isTrue,
        reason: 'level ${i + 1} should be free to explore',
      );
    }
  });

  test('level 6 stays locked until level 5 is finished', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 5,
        levels: pack.levels,
        starsByLevelId: const {},
      ),
      isFalse,
    );
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 5,
        levels: pack.levels,
        starsByLevelId: const {},
        completedLevelIds: {pack.levels[4].id},
      ),
      isTrue,
    );
  });

  test('finishing with zero stars still unlocks the next level', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 5,
        levels: pack.levels,
        starsByLevelId: {pack.levels[4].id: 0},
        completedLevelIds: {pack.levels[4].id},
      ),
      isTrue,
    );
  });

  test('recorded stars still count as finished for older progress', () {
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 6,
        levels: pack.levels,
        starsByLevelId: {pack.levels[5].id: 1},
      ),
      isTrue,
    );
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 6,
        levels: pack.levels,
        starsByLevelId: {pack.levels[4].id: 3},
      ),
      isFalse,
    );
  });

  test('a zero-star run is stored as completed', () async {
    final progress = ProgressStore(persist: false);
    await progress.recordBest(pack.levels[4].id, 0);
    expect(progress.starsFor(pack.levels[4].id), 0);
    expect(progress.hasCompleted(pack.levels[4].id), isTrue);
    expect(
      LevelUnlock.isUnlocked(
        levelIndex: 5,
        levels: pack.levels,
        starsByLevelId: progress.starsByLevelId,
        completedLevelIds: progress.completedLevelIds,
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
