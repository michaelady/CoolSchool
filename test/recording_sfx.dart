import 'package:coolschool/audio/sfx_service.dart';
import 'package:coolschool/game/session_settings.dart';

/// Test double that records which cues fired and whether mute blocked them.
class RecordingSfx implements SfxService {
  RecordingSfx(this.settings);

  final SessionSettings settings;
  final List<String> events = [];

  void _record(String name) {
    events.add(settings.muted ? 'muted:$name' : name);
  }

  @override
  Future<void> correct() async => _record('correct');

  @override
  Future<void> wrong() async => _record('wrong');

  @override
  Future<void> levelUp() async => _record('levelup');

  @override
  Future<void> transition() async => _record('transition');

  @override
  Future<void> next() async => _record('next');
}
