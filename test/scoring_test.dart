import 'package:coolschool/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunScore.stars', () {
    test('empty run is zero stars', () {
      expect(const RunScore(correct: 0, total: 0).stars, 0);
    });

    test('no correct answers is zero stars', () {
      expect(const RunScore(correct: 0, total: 6).stars, 0);
    });

    test('one third earns one star', () {
      expect(const RunScore(correct: 2, total: 6).stars, 1);
    });

    test('two thirds earns two stars', () {
      expect(const RunScore(correct: 4, total: 6).stars, 2);
    });

    test('perfect run earns three stars', () {
      expect(const RunScore(correct: 6, total: 6).stars, 3);
    });

    test('just below two thirds stays at one star', () {
      expect(const RunScore(correct: 3, total: 6).stars, 1);
    });

    test('passed requires at least one star', () {
      expect(const RunScore(correct: 1, total: 6).passed, isFalse);
      expect(const RunScore(correct: 2, total: 6).passed, isTrue);
    });
  });

  group('RunRecorder', () {
    test('marks answers and completes the run', () {
      final run = RunRecorder(total: 3);
      run.mark(true);
      run.mark(false);
      expect(run.isComplete, isFalse);
      run.mark(true);
      expect(run.isComplete, isTrue);
      expect(run.score.correct, 2);
      expect(run.score.stars, 2);
    });
  });
}
