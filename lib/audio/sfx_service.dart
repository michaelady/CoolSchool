import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../game/session_settings.dart';
import 'web_sfx.dart';

const sfxNames = ['correct', 'wrong', 'levelup', 'transition', 'next'];

/// Public so tests can lock the GitHub Pages / Flutter-web asset URL.
String webSoundUrl(String name, {Uri? page}) {
  final origin = page ?? Uri.base;
  final path = origin.path.endsWith('/') ? origin.path : '${origin.path}/';
  // `flutter build web` copies pubspec assets to assets/<assetKey>, so
  // `assets/sounds/foo.wav` is served as `assets/assets/sounds/foo.wav`.
  return '${origin.origin}${path}assets/assets/sounds/$name.wav';
}

abstract class SfxService {
  Future<void> preload() async {}

  Future<void> correct();
  Future<void> wrong();
  Future<void> levelUp();
  Future<void> transition();
  Future<void> next();
}

class NoopSfx implements SfxService {
  const NoopSfx();

  @override
  Future<void> preload() async {}

  @override
  Future<void> correct() async {}

  @override
  Future<void> wrong() async {}

  @override
  Future<void> levelUp() async {}

  @override
  Future<void> transition() async {}

  @override
  Future<void> next() async {}
}

class AssetSfx implements SfxService {
  AssetSfx({required this.settings, AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final SessionSettings settings;
  final AudioPlayer _player;
  final Map<String, Uint8List> _bytes = {};

  @override
  Future<void> preload() async {
    for (final name in sfxNames) {
      try {
        final data = await rootBundle.load('assets/sounds/$name.wav');
        _bytes[name] = data.buffer.asUint8List();
      } catch (error) {
        debugPrint('CoolSchool SFX preload failed: $name $error');
      }
    }
  }

  Future<void> _play(String name) async {
    if (playHtmlSfx(name, muted: settings.muted)) return;
    if (settings.muted) return;
    try {
      // Do not await stop() first — that drops the Chrome user-gesture token
      // and the whoosh is then blocked by autoplay policy.
      final bytes = _bytes[name];
      if (bytes != null) {
        await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
        return;
      }
      if (kIsWeb) {
        await _player.play(UrlSource(webSoundUrl(name), mimeType: 'audio/wav'));
        return;
      }
      await _player.play(AssetSource('sounds/$name.wav'));
    } catch (error) {
      debugPrint('CoolSchool SFX play failed: $name $error');
      if (kIsWeb) {
        try {
          await _player.play(UrlSource(webSoundUrl(name), mimeType: 'audio/wav'));
        } catch (fallback) {
          debugPrint('CoolSchool SFX url fallback failed: $name $fallback');
        }
      }
    }
  }

  @override
  Future<void> correct() => _play('correct');

  @override
  Future<void> wrong() => _play('wrong');

  @override
  Future<void> levelUp() => _play('levelup');

  @override
  Future<void> transition() => _play('transition');

  @override
  Future<void> next() => _play('next');
}
