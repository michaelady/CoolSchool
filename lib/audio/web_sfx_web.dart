import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Play a whoosh from a real `<audio>` tag (see web/index.html).
///
/// audioplayers `AssetSource` 404s on GitHub Pages (`/assets/sounds` vs
/// `/assets/assets/sounds`), and `await stop()` before `play()` drops the
/// Chrome user-gesture token — the tab then shows no audio indicator.
bool playHtmlSfx(String name, {required bool muted}) {
  final el = web.document.getElementById('coolschool-sfx-$name');
  if (el == null || !el.isA<web.HTMLAudioElement>()) return false;
  final audio = el as web.HTMLAudioElement;
  audio.muted = muted;
  if (muted) return true;
  try {
    audio.currentTime = 0;
    audio.play();
    return true;
  } catch (_) {
    return false;
  }
}
