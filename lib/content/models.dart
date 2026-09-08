import 'dart:convert';

import 'answer_check.dart';

/// PER (Plan d’études romand) competence tag, with a LP21-shaped payload
/// so existing UI can keep showing `competenceId + label`.
class Lp21Ref {
  const Lp21Ref({
    required this.competenceId,
    required this.label,
    required this.focusId,
    required this.focusLabel,
    required this.cycle,
  });

  final String competenceId;
  final String label;
  final String focusId;
  final String focusLabel;
  final String cycle;

  String get badge => '$competenceId $label';

  factory Lp21Ref.fromJson(Map<String, dynamic> json) {
    return Lp21Ref(
      competenceId: json['competenceId'] as String,
      label: json['label'] as String,
      focusId: json['focusId'] as String,
      focusLabel: json['focusLabel'] as String,
      cycle: json['cycle'] as String,
    );
  }
}

enum ExerciseKind { math, counting, vocab, quiz }

enum AnswerMode { choice, type }

enum ExerciseKeyboard { text, number }

class Exercise {
  const Exercise({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.promptTts,
    required this.answerMode,
    this.choices = const [],
    this.correctIndex = 0,
    this.acceptedAnswers = const [],
    this.keyboard = ExerciseKeyboard.text,
    this.items = const [],
    this.visual,
  });

  final String id;
  final ExerciseKind kind;
  final String prompt;
  final String promptTts;
  final AnswerMode answerMode;
  final List<String> choices;
  final int correctIndex;
  final List<String> acceptedAnswers;
  final ExerciseKeyboard keyboard;
  final List<String> items;
  final String? visual;

  bool get isType => answerMode == AnswerMode.type;
  bool get isChoice => answerMode == AnswerMode.choice;

  String get correctChoice =>
      choices.isEmpty ? (acceptedAnswers.isEmpty ? '' : acceptedAnswers.first) : choices[correctIndex];

  bool isCorrect(int index) => index == correctIndex;

  bool acceptsTyped(String raw) {
    final accepted = acceptedAnswers.isNotEmpty
        ? acceptedAnswers
        : (choices.isEmpty ? const <String>[] : [choices[correctIndex]]);
    return AnswerCheck.matches(raw, accepted);
  }

  bool get usesPictureChoices {
    if (choices.isEmpty) return false;
    return choices.every(_looksLikePicture);
  }

  static bool _looksLikePicture(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return !RegExp(r'[A-Za-zÀ-ÿĂăÂâÎîȘșȚț0-9]').hasMatch(trimmed);
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final answerMode = parseAnswerMode(json['answerMode'] as String?);
    final choices = (json['choices'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList(growable: false) ??
        const <String>[];
    final accepted = (json['acceptedAnswers'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList(growable: false) ??
        const <String>[];
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList(growable: false) ??
        const <String>[];
    if (answerMode == AnswerMode.type) {
      final answers = accepted.isNotEmpty
          ? accepted
          : (choices.isNotEmpty && json['correctIndex'] is int
              ? <String>[choices[json['correctIndex'] as int]]
              : const <String>[]);
      if (answers.isEmpty) {
        throw const FormatException('Typed exercise needs acceptedAnswers');
      }
      return Exercise(
        id: json['id'] as String,
        kind: parseExerciseKind(json['kind'] as String?),
        prompt: json['prompt'] as String,
        promptTts: json['promptTts'] as String,
        answerMode: AnswerMode.type,
        choices: choices,
        correctIndex: json['correctIndex'] as int? ?? 0,
        acceptedAnswers: answers,
        keyboard: parseExerciseKeyboard(json['keyboard'] as String?),
        items: items,
        visual: json['visual'] as String?,
      );
    }
    if (choices.length < 2) {
      throw const FormatException('Exercise needs at least 2 choices');
    }
    final correctIndex = json['correctIndex'] as int;
    if (correctIndex < 0 || correctIndex >= choices.length) {
      throw const FormatException('correctIndex is out of range');
    }
    return Exercise(
      id: json['id'] as String,
      kind: parseExerciseKind(json['kind'] as String?),
      prompt: json['prompt'] as String,
      promptTts: json['promptTts'] as String,
      answerMode: AnswerMode.choice,
      choices: choices,
      correctIndex: correctIndex,
      acceptedAnswers: accepted.isNotEmpty ? accepted : [choices[correctIndex]],
      keyboard: parseExerciseKeyboard(json['keyboard'] as String?),
      items: items,
      visual: json['visual'] as String?,
    );
  }
}

ExerciseKind parseExerciseKind(String? raw) {
  return switch (raw) {
    'counting' => ExerciseKind.counting,
    'vocab' => ExerciseKind.vocab,
    'quiz' => ExerciseKind.quiz,
    _ => ExerciseKind.math,
  };
}

AnswerMode parseAnswerMode(String? raw) {
  return raw == 'type' ? AnswerMode.type : AnswerMode.choice;
}

ExerciseKeyboard parseExerciseKeyboard(String? raw) {
  return raw == 'number' ? ExerciseKeyboard.number : ExerciseKeyboard.text;
}

class Level {
  const Level({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lp21Tag,
    required this.unlockAfterStars,
    required this.exercises,
  });

  final String id;
  final String title;
  final String subtitle;
  final String lp21Tag;
  final int unlockAfterStars;
  final List<Exercise> exercises;

  factory Level.fromJson(Map<String, dynamic> json) {
    final exercises = (json['exercises'] as List<dynamic>)
        .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    if (exercises.isEmpty) {
      throw const FormatException('Level needs at least one exercise');
    }
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      lp21Tag: (json['perTag'] ?? json['lp21Tag']) as String,
      unlockAfterStars: json['unlockAfterStars'] as int? ?? 0,
      exercises: exercises,
    );
  }
}

class ContentPack {
  const ContentPack({
    required this.id,
    required this.locale,
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.lp21,
    required this.levels,
  });

  final String id;
  final String locale;
  final String emoji;
  final String color;
  final String title;
  final String subtitle;
  final Lp21Ref lp21;
  final List<Level> levels;

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    final levels = (json['levels'] as List<dynamic>)
        .map((item) => Level.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    if (levels.isEmpty) {
      throw const FormatException('Pack needs at least one level');
    }
    final curriculum = json['per'] ?? json['lp21'];
    if (curriculum is! Map<String, dynamic>) {
      throw const FormatException('Pack needs a per (or lp21) block');
    }
    return ContentPack(
      id: json['id'] as String,
      locale: json['locale'] as String,
      emoji: json['emoji'] as String,
      color: json['color'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      lp21: Lp21Ref.fromJson(curriculum),
      levels: levels,
    );
  }

  static ContentPack fromJsonString(String source) {
    return ContentPack.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}

class ComingSoonTopic {
  const ComingSoonTopic({
    required this.id,
    required this.emoji,
    required this.color,
    required this.titleKey,
  });

  final String id;
  final String emoji;
  final String color;
  final String titleKey;
}
