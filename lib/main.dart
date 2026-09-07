import 'package:flutter/material.dart';

import 'app.dart';
import 'audio/sfx_service.dart';
import 'audio/speech_service.dart';
import 'content/pack_repository.dart';
import 'game/progress_store.dart';
import 'game/session_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = ProgressStore();
  final settings = SessionSettings();
  await progress.load();
  runApp(
    CoolSchoolApp(
      settings: settings,
      progress: progress,
      packs: const AssetPackRepository(),
      speech: FlutterTtsSpeech(),
      sfx: AssetSfx(settings: settings),
    ),
  );
}
