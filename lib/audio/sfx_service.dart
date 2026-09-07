import 'package:audioplayers/audioplayers.dart';

abstract class SfxService {
  Future<void> correct({required bool muted});
  Future<void> wrong({required bool muted});
  Future<void> levelUp({required bool muted});
}

class NoopSfx implements SfxService {
  const NoopSfx();

  @override
  Future<void> correct({required bool muted}) async {}

  @override
  Future<void> wrong({required bool muted}) async {}

  @override
  Future<void> levelUp({required bool muted}) async {}
}

class AssetSfx implements SfxService {
  AssetSfx({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<void> _play(String asset, {required bool muted}) async {
    if (muted) return;
    await _player.stop();
    await _player.play(AssetSource(asset));
  }

  @override
  Future<void> correct({required bool muted}) =>
      _play('sounds/correct.wav', muted: muted);

  @override
  Future<void> wrong({required bool muted}) =>
      _play('sounds/wrong.wav', muted: muted);

  @override
  Future<void> levelUp({required bool muted}) =>
      _play('sounds/levelup.wav', muted: muted);
}
