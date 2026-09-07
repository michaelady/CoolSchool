import 'package:web/web.dart' as web;

const webAnswerFeedbackId = 'coolschool-answer-feedback';

/// Browser-owned banner so Chrome testers see Richtig/Schade in the DOM.
/// Appended on [document.documentElement] with inline z-index so it sits
/// above Flutter's full-screen CanvasKit / glass pane.
void showWebAnswerFeedback({required bool correct, required String label}) {
  final existing = web.document.getElementById(webAnswerFeedbackId);
  final el = (existing ?? web.HTMLDivElement()) as web.HTMLElement;
  el.id = webAnswerFeedbackId;
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', 'assertive');
  el.setAttribute('data-correct', correct ? 'true' : 'false');
  el.setAttribute('data-testid', 'answer-feedback');
  el.textContent = label;
  el.style
    ..setProperty('position', 'fixed')
    ..setProperty('top', '68px')
    ..setProperty('left', '50%')
    ..setProperty('transform', 'translateX(-50%)')
    ..setProperty('z-index', '2147483647')
    ..setProperty('display', 'block')
    ..setProperty('opacity', '1')
    ..setProperty('visibility', 'visible')
    ..setProperty('pointer-events', 'none');
  if (existing == null) {
    web.document.documentElement?.append(el);
  }
}

void hideWebAnswerFeedback() {
  web.document.getElementById(webAnswerFeedbackId)?.remove();
}
