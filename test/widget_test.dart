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

ContentPack samplePack([String file = 'math_sciences_de.json']) {
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
      "id": "math_sciences-l${l + 1}",
      "title": "${levels == 1 ? 'Mini' : 'Mini ${l + 1}'}",
      "subtitle": "Kurz",
      "lp21Tag": "MA.1.A",
      "unlockAfterStars": ${l == 0 ? 0 : 1},
      "exercises": [$items]
    }'''
  ].join(',\n');
  return ContentPack.fromJsonString('''
{
  "id": "math_sciences",
  "locale": "de",
  "emoji": "+",
  "color": "#FF8A5B",
  "title": "$title",
  "subtitle": "Plus",
  "per": {
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
}) async {
  await tester.tap(find.text(topic));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey<String>('level-1')));
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
    expect(ro.left - en.right, lessThan(24), reason: 'RO must sit next to EN in the header');
    expect(
      ro.top < en.bottom + 16 || (en.left < ro.left && ro.left - en.right < 24),
      isTrue,
      reason: 'RO must be in the header with the other chips, not under the sun',
    );
    final sun = tester.getRect(find.byKey(const ValueKey<String>('home-sun')));
    for (final rect in [de, fr, en, ro]) {
      expect(rect.bottom, lessThanOrEqualTo(sun.top + 0.5), reason: 'language chip is under the sun hero');
      expect(rect.overlaps(sun), isFalse, reason: 'language chip intersects the sun hero');
    }
    expect(find.text('Mathematik & Natur'), findsOneWidget);
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
    final sun = tester.getRect(find.byKey(const ValueKey<String>('home-sun')));
    for (final code in ['de', 'fr', 'en', 'ro']) {
      final rect = tester.getRect(find.byKey(ValueKey<String>('locale-chip-$code')));
      expect(rect.overlaps(sun), isFalse, reason: '$code overlaps the sun on a phone width');
    }
  });

  testWidgets('chips stay above the sun at the tester 1280x800 desktop size', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    final sun = tester.getRect(find.byKey(const ValueKey<String>('home-sun')));
    for (final code in ['de', 'fr', 'en', 'ro']) {
      expectChipOnScreen(tester, code);
      final rect = tester.getRect(find.byKey(ValueKey<String>('locale-chip-$code')));
      expect(rect.bottom, lessThanOrEqualTo(sun.top + 0.5));
      expect(rect.overlaps(sun), isFalse, reason: '$code is under the sun at 1280x800');
    }
  });

  testWidgets('language chips switch EN and RO chrome strings', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('No account'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('No account'), findsOneWidget);
    expect(find.textContaining('No ads'), findsOneWidget);

    await tester.tap(find.text('RO'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Fără cont'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Fără cont'), findsOneWidget);
    expect(find.textContaining('Fără reclame'), findsOneWidget);
  });

  testWidgets('home lists all six PER domain cards', (tester) async {
    await pumpApp(
      tester,
      packs: [
        samplePack('langues_de.json'),
        samplePack('math_sciences_de.json'),
        samplePack('shs_de.json'),
        samplePack('arts_de.json'),
        samplePack('corps_de.json'),
        samplePack('numerique_de.json'),
      ],
    );
    expect(find.byKey(const ValueKey<String>('domain-langues')), findsOneWidget);
    expect(find.text('Sprachen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mathematik & Natur'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mathematik & Natur'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Digitale Bildung'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mensch & Gesellschaft'), findsOneWidget);
    expect(find.text('Künste'), findsOneWidget);
    expect(find.text('Körper & Bewegung'), findsOneWidget);
    expect(find.text('Digitale Bildung'), findsOneWidget);
  });

  testWidgets('home to topic to first exercise has a back path', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Mathematik & Natur'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('level-1')), findsOneWidget);
    expect(find.text('Wähle ein Level'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    expect(find.text('Vorlesen'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('level-1')), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('CoolSchool'), findsOneWidget);
  });

  testWidgets('math domain still has addition and counting', (tester) async {
    await pumpApp(tester, pack: samplePack('math_sciences_de.json'));
    await tester.tap(find.text('Mathematik & Natur'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 + 1 = ?'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Wie viele?'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('count-item-0')), findsOneWidget);
  });

  testWidgets('langues picture match is playable', (tester) async {
    await pumpApp(tester, pack: samplePack('langues_de.json'));
    await tester.tap(find.text('Sprachen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('Buch'), findsOneWidget);
    expect(find.text('📚'), findsOneWidget);
  });

  testWidgets('typing an answer holds Richtig like a tap', (tester) async {
    final typed = ContentPack.fromJsonString('''
{
  "id": "math_sciences",
  "locale": "de",
  "emoji": "+",
  "color": "#FF8A5B",
  "title": "Addition",
  "subtitle": "Plus",
  "per": {
    "competenceId": "MSN 16",
    "label": "Zahl",
    "focusId": "MSN 17",
    "focusLabel": "Operieren",
    "cycle": "Zyklus 1"
  },
  "levels": [{
    "id": "math_sciences-l1",
    "title": "Mini",
    "subtitle": "Kurz",
    "perTag": "MSN 16",
    "unlockAfterStars": 0,
    "exercises": [{
      "id": "t0",
      "prompt": "1 + 1 = ?",
      "promptTts": "eins plus eins",
      "answerMode": "type",
      "acceptedAnswers": ["2"],
      "keyboard": "number",
      "kind": "math"
    }]
  }]
}
''');
    await pumpApp(tester, pack: typed);
    await openFirstExercise(tester);
    expect(find.byKey(const ValueKey<String>('type-answer')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey<String>('type-answer')), '2');
    await tester.tap(find.byKey(const ValueKey<String>('type-submit')));
    await tester.pump();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('answer-feedback-banner')), findsOneWidget);
    await tester.pump(ExercisePage.answerFeedbackHold);
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);
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
    expect(progress.starsFor('math_sciences-l1'), 3);
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
