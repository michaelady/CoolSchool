import 'dart:js_interop';

import 'package:web/web.dart' as web;

const webLocaleBarId = 'coolschool-locales';

void Function(String locale)? _onSelect;
bool _wired = false;

/// Browser-owned DE/FR/EN/RO chips. CanvasKit Wrap dropped RO at 1280×800
/// even though the labels were in the JS bundle.
void showWebLocaleBar({
  required String selected,
  required void Function(String locale) onSelect,
}) {
  _onSelect = onSelect;
  final bar = web.document.getElementById(webLocaleBarId);
  if (bar == null) return;
  final host = bar as web.HTMLElement;
  host.style
    ..setProperty('display', 'flex', 'important')
    ..setProperty('visibility', 'visible', 'important');
  for (final code in const ['de', 'fr', 'en', 'ro']) {
    final btn = web.document.getElementById('coolschool-locale-$code');
    btn?.setAttribute('data-selected', selected == code ? 'true' : 'false');
  }
  if (_wired) return;
  _wired = true;
  host.addEventListener(
    'click',
    (web.Event event) {
      final target = event.target;
      if (target == null || !target.isA<web.Element>()) return;
      final code = (target as web.Element).closest('button')?.getAttribute('data-locale');
      if (code == null || code.isEmpty) return;
      _onSelect?.call(code);
    }.toJS,
  );
}

void hideWebLocaleBar() {
  _onSelect = null;
  final bar = web.document.getElementById(webLocaleBarId);
  if (bar == null) return;
  (bar as web.HTMLElement).style.setProperty('display', 'none');
}
