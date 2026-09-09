import 'tts_packs.dart';

/// VM / Android: the eSpeak JS engine is not here. Same [TtsLanguagePack]
/// ids stay ready for a future native plugin; [isAvailable] is false.
class BundledTts {
  BundledTts._();

  static final BundledTts instance = BundledTts._();

  bool get isAvailable => false;

  Future<void> loadPack(TtsLanguagePack pack) async {}

  Future<void> speak(String text, TtsLanguagePack pack) async {}

  Future<void> stop() async {}
}
