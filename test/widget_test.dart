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

ContentPack samplePack([String file = 'addition_de.json']) {
  return ContentPack.fromJsonString(
    File('assets/content/packs/$file').readAsStringSync(),
  );
}

ContentPack tinyPack({int exercises = 1, int levels = 1, String title = 'Addition'}) {
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
  "title": "$title",
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
  List<ContentPack>? packs,
  ProgressStore? progress,
  SessionSettings? settings,
  SfxService? sfx,
}) {
  final content = packs ?? [pack ?? samplePack()];
  return CoolSchoolApp(
    settings: settings ?? SessionSettings(),
    progress: progress ?? ProgressStore(persist: false),
    packs: MemoryPackRepository.all(content),
    speech: const NoopSpeech(),
    sfx: sfx ?? const NoopSfx(),
  );
}

Future<void> pumpApp(
  WidgetTester tester, {
  ContentPack? pack,
  List<ContentPack>? packs,
  ProgressStore? progress,
  SessionSettings? settings,
  SfxService? sfx,
}) async {
  await tester.pumpWidget(
    app(pack: pack, packs: packs, progress: progress, settings: settings, sfx: sfx),
  );
  await tester.pumpAndSettle();
}

Future<void> openFirstExercise(
  WidgetTester tester, {
  String topic = 'Addition',
  String level = 'Mini',
}) async {
  await tester.tap(find.text(topic));
  await tester.pumpAndSettle();
  await tester.tap(find.text(level));
  await tester.pumpAndSettle();
}

void main() {
  void expectChipOnScreen(WidgetTester tester, String code) {
    final finder = find.byKey(ValueKey<String>('locale-chip-$code'));
    expect(finder, findsOneWidget, reason: 'missing $code chip');
    expect(find.text(code.toUpperCase()), findsOneWidget);
    final rect = tester.getRect(finder);
    final surface = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.width, greaterThan(24), reason: '$code chip too narrow');
    expect(rect.height, greaterThan(24), reason: '$code chip too short');
    expect(rect.left, greaterThanOrEqualTo(-0.5), reason: '$code clipped left');
    expect(rect.top, greaterThanOrEqualTo(-0.5), reason: '$code clipped top');
    expect(rect.right, lessThanOrEqualTo(surface.width + 0.5), reason: '$code clipped right');
    expect(rect.bottom, lessThanOrEqualTo(surface.height + 0.5), reason: '$code clipped bottom');
  }

  testWidgets('home shows four language chips and stays ad-free', (tester) async {
    await pumpApp(tester);
    expect(find.text('CoolSchool'), findsOneWidget);
    for (final code in ['de', 'fr', 'en', 'ro']) {
      expectChipOnScreen(tester, code);
    }
    final de = tester.getRect(find.byKey(const ValueKey<String>('locale-chip-de')));
    final fr = tester.getRect(find.byKey(const ValueKey<String>('locale-chip-fr')));
    final en = tester.getRect(find.byKey(const ValueKey<String>('locale-chip-en')));
    final ro = tester.getRect(find.byKey(const ValueKey<String>('locale-chip-ro')));
    expect(de.left < fr.left && fr.left < en.left && en.left < ro.left, isTrue);
    expect(ro.left - en.right, lessThan(20), reason: 'RO must sit next to EN, not across the header');
    expect(find.text('Addition'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Kein Login'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Kein Login'), findsOneWidget);
    expect(find.textContaining('Werbung'), findsOneWidget);
  });

  testWidgets('RO chip stays on screen on a narrow phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    for (final code in ['de', 'fr', 'en', 'ro']) {
      expectChipOnScreen(tester, code);
    }
  });

  testWidgets('language chips switch EN and RO chrome strings', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No account'), findsOneWidget);
    expect(find.textContaining('No ads'), findsOneWidget);

    await tester.tap(find.text('RO'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fără cont'), findsOneWidget);
    expect(find.textContaining('Fără reclame'), findsOneWidget);
  });

  testWidgets('home lists subtraction, counting, and school words', (tester) async {
    await pumpApp(
      tester,
      packs: [
        samplePack('addition_de.json'),
        samplePack('subtraction_de.json'),
        samplePack('counting_de.json'),
        samplePack('vocab_de.json'),
      ],
    );
    expect(find.text('Addition'), findsOneWidget);
    expect(find.text('Subtraktion'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Zählen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Zählen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Schulsprache'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Schulsprache'), findsOneWidget);
  });

  testWidgets('home to topic to first exercise has a back path', (tester) async {
    await pumpApp(tester);
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

  testWidgets('subtraction and counting are playable', (tester) async {
    await pumpApp(
      tester,
      packs: [
        samplePack('subtraction_de.json'),
        samplePack('counting_de.json'),
      ],
    );

    await tester.tap(find.text('Subtraktion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wegnehmen'));
    await tester.pumpAndSettle();
    expect(find.text('5 − 2 = ?'), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Zählen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Zählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kleine Mengen'));
    await tester.pumpAndSettle();
    expect(find.text('Wie viele?'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('count-item-0')), findsOneWidget);
  });

  testWidgets('vocab listen-or-match game is playable', (tester) async {
    await pumpApp(tester, pack: samplePack('vocab_de.json'));
    await tester.tap(find.text('Schulsprache'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wort und Bild'));
    await tester.pumpAndSettle();
    expect(find.text('Buch'), findsOneWidget);
    expect(find.text('📚'), findsOneWidget);
  });

  testWidgets('answering a short run awards stars', (tester) async {
    final tiny = tinyPack();
    final progress = ProgressStore(persist: false);
    await pumpApp(tester, pack: tiny, progress: progress);
    await openFirstExercise(tester);
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('answer-feedback-banner')), findsOneWidget);
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);
    expect(progress.starsFor('addition-l1'), 3);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('French feedback hold uses Bravo', (tester) async {
    final settings = SessionSettings()..setLocale('fr');
    await pumpApp(tester, pack: tinyPack(), settings: settings);
    await openFirstExercise(tester);
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Bravo !'), findsOneWidget);
    expect(find.text('Richtig!'), findsNothing);
  });

  testWidgets('chosen answer holds a clear correct or wrong visual and SFX', (tester) async {
    final settings = SessionSettings();
    final sfx = RecordingSfx(settings);
    await pumpApp(tester, pack: tinyPack(exercises: 2), settings: settings, sfx: sfx);
    await openFirstExercise(tester);

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('Schade!'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('answer-feedback-banner')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('answer-feedback-banner'))).height,
      greaterThan(48),
    );
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    expect(find.text('2 + 1 = ?'), findsNothing);
    expect(sfx.events, ['transition', 'transition', 'wrong']);

    // Hold must survive a near-full timer pump — this fails if feedback is
    // cleared in the same frame as the tap / advance.
    await tester.pump(ExercisePage.answerFeedbackHold - const Duration(milliseconds: 200));
    expect(find.text('Schade!'), findsOneWidget);
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    expect(find.text('2 + 1 = ?'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('2 + 1 = ?'), findsOneWidget);
    expect(find.text('Schade!'), findsNothing);
    expect(sfx.events, ['transition', 'transition', 'wrong', 'next']);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('answer-feedback-banner')), findsOneWidget);
    expect(sfx.events, ['transition', 'transition', 'wrong', 'next', 'correct']);

    await tester.pump(ExercisePage.answerFeedbackHold - const Duration(milliseconds: 200));
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.text('Super gemacht!'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);
    expect(sfx.events, ['transition', 'transition', 'wrong', 'next', 'correct', 'levelup']);
  });

  testWidgets('feedback banner appears after tap while hold timer is pending', (tester) async {
    await pumpApp(tester, pack: tinyPack(exercises: 2));
    await openFirstExercise(tester);

    expect(find.text('Richtig!'), findsNothing);
    expect(find.text('Schade!'), findsNothing);

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('answer-feedback-banner')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('answer-feedback-banner'))).height,
      greaterThan(48),
    );
    expect(find.text('Schade!'), findsNothing);
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    expect(find.text('2 + 1 = ?'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('answer-feedback-banner')), findsOneWidget);
    expect(find.text('2 + 1 = ?'), findsNothing);
  });

  testWidgets('reward Home returns to the home screen', (tester) async {
    await pumpApp(tester, pack: tinyPack());
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
    await pumpApp(tester, pack: tinyPack(exercises: 2), settings: settings, sfx: sfx);
    await openFirstExercise(tester);

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('mute-button')));
    await tester.pump();
    expect(settings.muted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(sfx.events, contains('muted:correct'));
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();

    expect(find.text('2 + 1 = ?'), findsOneWidget);
    expect(settings.muted, isTrue);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(sfx.events, contains('muted:next'));

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
