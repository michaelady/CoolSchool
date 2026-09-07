import 'package:web/web.dart' as web;

const webAnswerFeedbackId = 'coolschool-answer-feedback';

/// Browser-owned banner so Chrome testers see Richtig/Schade in the DOM.
///
/// Appended inside Flutter's view (or [document.body] as fallback) — not on
/// [document.documentElement]. A child of `<html>` sits *behind* the
/// full-screen CanvasKit glass pane, which is why Phase 2 testers saw no
/// hold after the overlay host moved to documentElement.
void showWebAnswerFeedback({required bool correct, required String label}) {
  final existing = web.document.getElementById(webAnswerFeedbackId);
  final el = (existing ?? web.HTMLDivElement()) as web.HTMLElement;
  el.id = webAnswerFeedbackId;
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', 'assertive');
  el.setAttribute('data-correct', correct ? 'true' : 'false');
  el.setAttribute('data-testid', 'answer-feedback');
  el.textContent = label;
  _applyHoldStyles(el);
  final host = _overlayHost();
  if (host != null && el.parentElement != host) {
    host.append(el);
  }
}

void hideWebAnswerFeedback() {
  web.document.getElementById(webAnswerFeedbackId)?.remove();
}

web.Element? _overlayHost() {
  return web.document.querySelector('flutter-view') ??
      web.document.querySelector('flt-glass-pane') ??
      web.document.body;
}

void _applyHoldStyles(web.HTMLElement el) {
  const important = 'important';
  el.style
    ..setProperty('position', 'fixed', important)
    ..setProperty('top', '68px', important)
    ..setProperty('left', '50%', important)
    ..setProperty('transform', 'translateX(-50%)', important)
    ..setProperty('z-index', '2147483647', important)
    ..setProperty('display', 'block', important)
    ..setProperty('opacity', '1', important)
    ..setProperty('visibility', 'visible', important)
    ..setProperty('pointer-events', 'none', important);
}
