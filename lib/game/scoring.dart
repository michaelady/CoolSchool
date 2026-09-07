import '../content/models.dart';

/// Stars earned for one short exercise run.
class RunScore {
  const RunScore({required this.correct, required this.total});

  final int correct;
  final int total;

  double get ratio => total == 0 ? 0 : correct / total;

  /// 3 perfect, 2 if at least two thirds, 1 if at least one third, else 0.
  int get stars {
    if (total <= 0 || correct <= 0) return 0;
    if (ratio >= 1) return 3;
    if (ratio >= 2 / 3) return 2;
    if (ratio >= 1 / 3) return 1;
    return 0;
  }

  bool get passed => stars >= 1;
}

class LevelUnlock {
  const LevelUnlock._();

  /// First level is always open. Later levels need enough stars on the
  /// immediately previous level.
  static bool isUnlocked({
    required int levelIndex,
    required List<Level> levels,
    required Map<String, int> starsByLevelId,
  }) {
    if (levelIndex < 0 || levelIndex >= levels.length) return false;
    if (levelIndex == 0) return true;
    final previous = levels[levelIndex - 1];
    final needed = levels[levelIndex].unlockAfterStars;
    return (starsByLevelId[previous.id] ?? 0) >= needed;
  }

  static int firstLockedIndex({
    required List<Level> levels,
    required Map<String, int> starsByLevelId,
  }) {
    for (var i = 0; i < levels.length; i++) {
      if (!isUnlocked(
        levelIndex: i,
        levels: levels,
        starsByLevelId: starsByLevelId,
      )) {
        return i;
      }
    }
    return levels.length;
  }
}

class RunRecorder {
  RunRecorder({required this.total});

  final int total;
  int correct = 0;
  int answered = 0;

  void mark(bool isCorrect) {
    answered += 1;
    if (isCorrect) correct += 1;
  }

  bool get isComplete => answered >= total;

  RunScore get score => RunScore(correct: correct, total: total);
}
