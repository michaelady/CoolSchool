import 'package:coolschool/content/answer_check.dart';
import 'package:coolschool/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnswerCheck', () {
    test('trims and ignores case', () {
      expect(AnswerCheck.matches(' Chat ', ['chat']), isTrue);
      expect(AnswerCheck.matches('CHAT', ['chat']), isTrue);
      expect(AnswerCheck.matches('  10  ', ['10']), isTrue);
    });

    test('is accent-tolerant for French and Romanian', () {
      expect(AnswerCheck.matches('ecole', ['école']), isTrue);
      expect(AnswerCheck.matches('ÉCOLE', ['école']), isTrue);
      expect(AnswerCheck.matches('scoala', ['școală']), isTrue);
      expect(AnswerCheck.matches('apa', ['apă']), isTrue);
      expect(AnswerCheck.matches('mana', ['mână']), isTrue);
    });

    test('rejects a different word', () {
      expect(AnswerCheck.matches('chat', ['chien']), isFalse);
      expect(AnswerCheck.matches('', ['chat']), isFalse);
      expect(AnswerCheck.matches('   ', ['2']), isFalse);
    });

    test('typed exercise accepts normalized answers', () {
      final exercise = Exercise.fromJson({
        'id': 't1',
        'prompt': 'Écris : école',
        'promptTts': 'Écris école',
        'answerMode': 'type',
        'acceptedAnswers': ['école'],
        'kind': 'vocab',
      });
      expect(exercise.isType, isTrue);
      expect(exercise.acceptsTyped('Ecole'), isTrue);
      expect(exercise.acceptsTyped('maison'), isFalse);
    });
  });
}
