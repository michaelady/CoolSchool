import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'audio/sfx_service.dart';
import 'audio/speech_service.dart';
import 'content/models.dart';
import 'content/pack_repository.dart';
import 'game/progress_store.dart';
import 'game/session_settings.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

class CoolSchoolApp extends StatelessWidget {
  const CoolSchoolApp({
    super.key,
    required this.settings,
    required this.progress,
    required this.packs,
    required this.speech,
    required this.sfx,
    this.initialPack,
  });

  final SessionSettings settings;
  final ProgressStore progress;
  final PackRepository packs;
  final SpeechService speech;
  final SfxService sfx;
  final ContentPack? initialPack;

  @override
  Widget build(BuildContext context) {
    // Do not rebuild MaterialApp when settings/progress change — that can
    // reset the navigator (Home becomes a new first route, mute chrome
    // remounts, reward Home no longer pops to the real home).
    return AppScope(
      settings: settings,
      progress: progress,
      packs: packs,
      speech: speech,
      sfx: sfx,
      child: MaterialApp(
        title: 'CoolSchool',
        debugShowCheckedModeBanner: false,
        theme: CoolTheme.data(),
        home: HomePage(initialPack: initialPack),
      ),
    );
  }
}
