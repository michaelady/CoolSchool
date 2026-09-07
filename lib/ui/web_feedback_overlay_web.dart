import 'package:web/web.dart' as web;

const webAnswerFeedbackId = 'coolschool-answer-feedback';

/// Browser-owned banner so Chrome testers see Bravo / Presque in the DOM.
///
/// Always appended as the last child of [document.body] (not `<html>`).
/// A child of `documentElement` paints *behind* Flutter's full-screen
/// CanvasKit view. [showPopover] puts the banner in the browser top layer
/// so the glass pane cannot cover it.
void showWebAnswerFeedback({required bool correct, required String label}) {
  final existing = web.document.getElementById(webAnswerFeedbackId);
  final el = (existing ?? web.HTMLDivElement()) as web.HTMLElement;
  el.id = webAnswerFeedbackId;
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', 'assertive');
  el.setAttribute('data-correct', correct ? 'true' : 'false');
  el.setAttribute('data-testid', 'answer-feedback');
  el.setAttribute('popover', 'manual');
  el.textContent = label;
  _applyHoldStyles(el);
  web.document.body?.append(el);
  try {
    el.showPopover();
  } catch (_) {
    // Already open, or the browser has no Popover API — body + z-index remain.
  }
}

void hideWebAnswerFeedback() {
  final el = web.document.getElementById(webAnswerFeedbackId);
  if (el == null) return;
  try {
    (el as web.HTMLElement).hidePopover();
  } catch (_) {}
  el.remove();
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
