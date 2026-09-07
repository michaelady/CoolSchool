import 'dart:io';

import 'package:coolschool/audio/sfx_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transition and next wavs are bundled with the other cues', () async {
    for (final name in sfxNames) {
      final data = await rootBundle.load('assets/sounds/$name.wav');
      expect(data.lengthInBytes, greaterThan(2000), reason: '$name.wav missing or tiny');
    }
  });

  test('web sound URLs use the Flutter web assets/assets nest', () {
    expect(
      webSoundUrl('transition', page: Uri.parse('https://michaelady.github.io/CoolSchool/')),
      'https://michaelady.github.io/CoolSchool/assets/assets/sounds/transition.wav',
    );
    expect(
      webSoundUrl('next', page: Uri.parse('https://michaelady.github.io/CoolSchool/?v=p2')),
      'https://michaelady.github.io/CoolSchool/assets/assets/sounds/next.wav',
    );
    expect(
      webSoundUrl('correct', page: Uri.parse('http://localhost:8080/')),
      'http://localhost:8080/assets/assets/sounds/correct.wav',
    );
    expect(webSoundUrl('next', page: Uri.parse('https://example.test/app/?v=p2')), isNot(contains('?')));
  });

  test('index.html ships whoosh audio tags', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('coolschool-sfx-transition'));
    expect(html, contains('assets/assets/sounds/transition.wav'));
    expect(html, contains('coolschool-sfx-next'));
    expect(html, isNot(contains('coolschool-locale-ro')));
  });
}
