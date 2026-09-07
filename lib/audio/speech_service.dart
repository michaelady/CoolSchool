import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechService {
  Future<void> speak(String text, {required String locale, required bool muted});
  Future<void> stop();
}

class NoopSpeech implements SpeechService {
  const NoopSpeech();

  @override
  Future<void> speak(
    String text, {
    required String locale,
    required bool muted,
  }) async {}

  @override
  Future<void> stop() async {}
}

class FlutterTtsSpeech implements SpeechService {
  FlutterTtsSpeech({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(false);
    await _tts.setVolume(1);
    await _tts.setPitch(1.08);
    _ready = true;
  }

  @override
  Future<void> speak(
    String text, {
    required String locale,
    required bool muted,
  }) async {
    if (muted || text.trim().isEmpty) return;
    await _ensureReady();
    await _tts.stop();
    final lang = locale.startsWith('fr') ? 'fr-FR' : 'de-DE';
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.42);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
