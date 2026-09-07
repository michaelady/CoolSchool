import 'package:audioplayers/audioplayers.dart';

import '../game/session_settings.dart';

abstract class SfxService {
  Future<void> correct();
  Future<void> wrong();
  Future<void> levelUp();
}

class NoopSfx implements SfxService {
  const NoopSfx();

  @override
  Future<void> correct() async {}

  @override
  Future<void> wrong() async {}

  @override
  Future<void> levelUp() async {}
}

class AssetSfx implements SfxService {
  AssetSfx({required this.settings, AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final SessionSettings settings;
  final AudioPlayer _player;

  Future<void> _play(String asset) async {
    if (settings.muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Autoplay / missing plugin on some web hosts must not skip UI feedback.
    }
  }

  @override
  Future<void> correct() => _play('sounds/correct.wav');

  @override
  Future<void> wrong() => _play('sounds/wrong.wav');

  @override
  Future<void> levelUp() => _play('sounds/levelup.wav');
}
