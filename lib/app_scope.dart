import 'package:flutter/material.dart';

import 'audio/sfx_service.dart';
import 'audio/speech_service.dart';
import 'content/pack_repository.dart';
import 'game/progress_store.dart';
import 'game/session_settings.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.progress,
    required this.packs,
    required this.speech,
    required this.sfx,
    required super.child,
  });

  final SessionSettings settings;
  final ProgressStore progress;
  final PackRepository packs;
  final SpeechService speech;
  final SfxService sfx;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return settings != oldWidget.settings ||
        progress != oldWidget.progress ||
        packs != oldWidget.packs ||
        speech != oldWidget.speech ||
        sfx != oldWidget.sfx;
  }
}
