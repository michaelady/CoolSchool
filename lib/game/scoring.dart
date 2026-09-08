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

  /// First this many difficulties are always open so kids (ages ≤ 10) and QA
  /// can explore without grinding stars. Matches one easy cycle-1 band.
  static const int freeExploreCount = 5;

  /// Kid-friendly unlock (stars are a badge, not a gate):
  ///
  /// * Levels 1–[freeExploreCount] are always playable.
  /// * Level N (N > 5) opens after the previous level has been **finished**
  ///   at least once, even with 0 stars.
  ///
  /// Recorded stars still count as finished (older progress without a
  /// completion flag). JSON `unlockAfterStars` is catalog metadata only.
  static bool isUnlocked({
    required int levelIndex,
    required List<Level> levels,
    required Map<String, int> starsByLevelId,
    Iterable<String> completedLevelIds = const [],
  }) {
    if (levelIndex < 0 || levelIndex >= levels.length) return false;
    if (levelIndex < freeExploreCount) return true;
    final previous = levels[levelIndex - 1];
    if (completedLevelIds.contains(previous.id)) return true;
    return (starsByLevelId[previous.id] ?? 0) > 0;
  }

  static int firstLockedIndex({
    required List<Level> levels,
    required Map<String, int> starsByLevelId,
    Iterable<String> completedLevelIds = const [],
  }) {
    for (var i = 0; i < levels.length; i++) {
      if (!isUnlocked(
        levelIndex: i,
        levels: levels,
        starsByLevelId: starsByLevelId,
        completedLevelIds: completedLevelIds,
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
