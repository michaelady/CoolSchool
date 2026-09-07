import 'dart:io';

import 'package:coolschool/app.dart';
import 'package:coolschool/audio/sfx_service.dart';
import 'package:coolschool/audio/speech_service.dart';
import 'package:coolschool/content/models.dart';
import 'package:coolschool/content/pack_repository.dart';
import 'package:coolschool/game/progress_store.dart';
import 'package:coolschool/game/session_settings.dart';
import 'package:coolschool/ui/exercise_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_sfx.dart';

ContentPack samplePack() {
  return ContentPack.fromJsonString(
    File('assets/content/packs/addition_de.json').readAsStringSync(),
  );
}

ContentPack tinyPack({int exercises = 1, int levels = 1}) {
  final items = [
    for (var i = 0; i < exercises; i++)
      '''
        {
          "id": "m$i",
          "prompt": "${i + 1} + 1 = ?",
          "promptTts": "prompt $i",
          "choices": ["${i + 1}", "${i + 2}"],
          "correctIndex": 1
        }'''
  ].join(',\n');
  final levelBlocks = [
    for (var l = 0; l < levels; l++)
      '''
    {
      "id": "addition-l${l + 1}",
      "title": "${levels == 1 ? 'Mini' : 'Mini ${l + 1}'}",
      "subtitle": "Kurz",
      "lp21Tag": "MA.1.A",
      "unlockAfterStars": ${l == 0 ? 0 : 1},
      "exercises": [$items]
    }'''
  ].join(',\n');
  return ContentPack.fromJsonString('''
{
  "id": "addition",
  "locale": "de",
  "emoji": "+",
  "color": "#FF8A5B",
  "title": "Addition",
  "subtitle": "Plus",
  "lp21": {
    "competenceId": "MA.1",
    "label": "Zahl und Variable",
    "focusId": "MA.1.B",
    "focusLabel": "Operieren",
    "cycle": "Zyklus 1"
  },
  "levels": [$levelBlocks]
}
''');
}

Widget app({
  ContentPack? pack,
  ProgressStore? progress,
  SessionSettings? settings,
  SfxService? sfx,
}) {
  final content = pack ?? samplePack();
  return CoolSchoolApp(
    settings: settings ?? SessionSettings(),
    progress: progress ?? ProgressStore(persist: false),
    packs: MemoryPackRepository(content),
    speech: const NoopSpeech(),
    sfx: sfx ?? const NoopSfx(),
    initialPack: content,
  );
}

Future<void> openFirstExercise(WidgetTester tester, {String level = 'Mini'}) async {
  await tester.tap(find.text('Addition'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(level));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows Addition and stays ad-free', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('CoolSchool'), findsOneWidget);
    expect(find.text('Addition'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Kein Login'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Kein Login'), findsOneWidget);
    expect(find.textContaining('Werbung'), findsOneWidget);
  });

  testWidgets('home to topic to first exercise has a back path', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Addition'));
    await tester.pumpAndSettle();
    expect(find.text('Zahlenfreunde'), findsOneWidget);
    expect(find.text('Wähle ein Level'), findsOneWidget);

    await tester.tap(find.text('Zahlenfreunde'));
    await tester.pumpAndSettle();
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    expect(find.text('Vorlesen'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Zahlenfreunde'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('CoolSchool'), findsOneWidget);
  });

  testWidgets('answering a short run awards stars', (tester) async {
    final tiny = tinyPack();
    final progress = ProgressStore(persist: false);
    await tester.pumpWidget(app(pack: tiny, progress: progress));
    await openFirstExercise(tester);
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);
    expect(progress.starsFor('addition-l1'), 3);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('chosen answer holds a clear correct or wrong visual and SFX', (tester) async {
    final settings = SessionSettings();
    final sfx = RecordingSfx(settings);
    await tester.pumpWidget(app(pack: tinyPack(exercises: 2), settings: settings, sfx: sfx));
    await openFirstExercise(tester);

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('Schade!'), findsOneWidget);
    expect(find.text('2 + 1 = ?'), findsNothing);
    expect(sfx.events, ['wrong']);

    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('2 + 1 = ?'), findsOneWidget);
    expect(find.text('Schade!'), findsNothing);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(sfx.events, ['wrong', 'correct']);
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);
  });

  testWidgets('reward Home returns to the home screen', (tester) async {
    await tester.pumpWidget(app(pack: tinyPack()));
    await openFirstExercise(tester);
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('reward-home')));
    await tester.pumpAndSettle();
    expect(find.text('CoolSchool'), findsOneWidget);
    expect(find.text('Addition'), findsOneWidget);
    expect(find.text('Super gemacht!'), findsNothing);
    expect(find.text('1 + 1 = ?'), findsNothing);
  });

  testWidgets('mute stays on across the next exercise', (tester) async {
    final settings = SessionSettings();
    final sfx = RecordingSfx(settings);
    await tester.pumpWidget(app(pack: tinyPack(exercises: 2), settings: settings, sfx: sfx));
    await openFirstExercise(tester);

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('mute-button')));
    await tester.pump();
    expect(settings.muted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(sfx.events, ['muted:correct']);
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();

    expect(find.text('2 + 1 = ?'), findsOneWidget);
    expect(settings.muted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);

    await tester.tap(find.text('Nochmal'));
    await tester.pumpAndSettle();
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    expect(settings.muted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });
}
