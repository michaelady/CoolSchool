import 'dart:convert';

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

class Exercise {
  const Exercise({
    required this.id,
    required this.prompt,
    required this.promptTts,
    required this.choices,
    required this.correctIndex,
  });

  final String id;
  final String prompt;
  final String promptTts;
  final List<String> choices;
  final int correctIndex;

  String get correctChoice => choices[correctIndex];

  bool isCorrect(int index) => index == correctIndex;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>)
        .map((item) => item.toString())
        .toList(growable: false);
    final correctIndex = json['correctIndex'] as int;
    if (choices.length < 2) {
      throw const FormatException('Exercise needs at least 2 choices');
    }
    if (correctIndex < 0 || correctIndex >= choices.length) {
      throw const FormatException('correctIndex is out of range');
    }
    return Exercise(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      promptTts: json['promptTts'] as String,
      choices: choices,
      correctIndex: correctIndex,
    );
  }
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
      lp21Tag: json['lp21Tag'] as String,
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
    return ContentPack(
      id: json['id'] as String,
      locale: json['locale'] as String,
      emoji: json['emoji'] as String,
      color: json['color'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      lp21: Lp21Ref.fromJson(json['lp21'] as Map<String, dynamic>),
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
