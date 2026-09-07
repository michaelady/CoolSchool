import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'audio/sfx_service.dart';
import 'audio/speech_service.dart';
import 'content/pack_repository.dart';
import 'game/progress_store.dart';
import 'game/session_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Put exercise labels (Richtig! / Schade!) into the web semantics DOM so
  // Chrome testers can observe the hold, not only the JS bundle strings.
  if (kIsWeb) {
    WidgetsBinding.instance.ensureSemantics();
  }
  final progress = ProgressStore();
  final settings = SessionSettings();
  final sfx = AssetSfx(settings: settings);
  await progress.load();
  await sfx.preload();
  runApp(
    CoolSchoolApp(
      settings: settings,
      progress: progress,
      packs: const AssetPackRepository(),
      speech: FlutterTtsSpeech(),
      sfx: sfx,
    ),
  );
}
