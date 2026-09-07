import 'package:coolschool/game/session_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mute toggles and notifies for the whole session', () {
    final settings = SessionSettings();
    var ticks = 0;
    settings.addListener(() => ticks += 1);

    expect(settings.muted, isFalse);
    settings.toggleMute();
    expect(settings.muted, isTrue);
    settings.toggleMute();
    expect(settings.muted, isFalse);
    expect(ticks, 2);
  });

  test('locale switches between de and fr', () {
    final settings = SessionSettings();
    settings.setLocale('fr-CH');
    expect(settings.locale, 'fr');
    settings.setLocale('de');
    expect(settings.locale, 'de');
  });
}
