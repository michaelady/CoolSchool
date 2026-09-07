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

  test('locale normalizes BCP-47 tags to de/fr/en/ro', () {
    final settings = SessionSettings();
    settings.setLocale('fr-CH');
    expect(settings.locale, 'fr');
    settings.setLocale('en-GB');
    expect(settings.locale, 'en');
    settings.setLocale('ro-RO');
    expect(settings.locale, 'ro');
    settings.setLocale('de-DE');
    expect(settings.locale, 'de');
  });
}
