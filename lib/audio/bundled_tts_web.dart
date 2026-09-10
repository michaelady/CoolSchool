import 'dart:js_interop';

import 'tts_packs.dart';

@JS('CoolSchoolTts')
external CoolSchoolTtsJs? get _engine;

extension type CoolSchoolTtsJs(JSObject _) implements JSObject {
  external JSPromise<JSAny?> loadPack(String locale);
  external JSPromise<JSAny?> speak(String text, String locale);
  external JSPromise<JSAny?> stop();
}

/// Web: meSpeak + one voice JSON pack per UI language (`web/tts/`).
class BundledTts {
  BundledTts._();

  static final BundledTts instance = BundledTts._();

  bool get isAvailable => _engine != null;

  Future<void> loadPack(TtsLanguagePack pack) async {
    final engine = _engine;
    if (engine == null) return;
    await engine.loadPack(pack.locale).toDart;
  }

  Future<void> speak(String text, TtsLanguagePack pack) async {
    if (text.trim().isEmpty) return;
    if (pack.locale != 'en' && pack.voiceIdIsEnglish) {
      throw StateError('Refusing English bundled voice for ${pack.locale}');
    }
    final engine = _engine;
    if (engine == null) {
      throw StateError('CoolSchoolTts is not loaded');
    }
    try {
      await engine.speak(text, pack.locale).toDart;
    } catch (error) {
      // AbortError from an interrupted play() is handled in JS; anything
      // that still surfaces here must not become an unhandled rejection.
      if (_isAbortError(error)) return;
      rethrow;
    }
  }

  Future<void> stop() async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.stop().toDart;
    } catch (error) {
      if (_isAbortError(error)) return;
    }
  }
}

bool _isAbortError(Object error) {
  final text = error.toString();
  return text.contains('AbortError') ||
      text.contains('play() request was interrupted');
}
