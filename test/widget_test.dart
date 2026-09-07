import 'dart:io';

import 'package:coolschool/app.dart';
import 'package:coolschool/audio/sfx_service.dart';
import 'package:coolschool/audio/speech_service.dart';
import 'package:coolschool/content/models.dart';
import 'package:coolschool/content/pack_repository.dart';
import 'package:coolschool/game/progress_store.dart';
import 'package:coolschool/game/session_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ContentPack samplePack() {
  return ContentPack.fromJsonString(
    File('assets/content/packs/addition_de.json').readAsStringSync(),
  );
}

Widget app({ContentPack? pack, ProgressStore? progress}) {
  final content = pack ?? samplePack();
  return CoolSchoolApp(
    settings: SessionSettings(),
    progress: progress ?? ProgressStore(persist: false),
    packs: MemoryPackRepository(content),
    speech: const NoopSpeech(),
    sfx: const NoopSfx(),
    initialPack: content,
  );
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
    final tiny = ContentPack.fromJsonString('''
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
  "levels": [
    {
      "id": "addition-l1",
      "title": "Mini",
      "subtitle": "Kurz",
      "lp21Tag": "MA.1.A",
      "unlockAfterStars": 0,
      "exercises": [
        {
          "id": "m1",
          "prompt": "1 + 1 = ?",
          "promptTts": "eins plus eins",
          "choices": ["1", "2"],
          "correctIndex": 1
        }
      ]
    }
  ]
}
''');
    final progress = ProgressStore(persist: false);
    await tester.pumpWidget(app(pack: tiny, progress: progress));
    await tester.tap(find.text('Addition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Super gemacht!'), findsWidgets);
    expect(progress.starsFor('addition-l1'), 3);
    expect(find.text('Home'), findsOneWidget);
  });
}
