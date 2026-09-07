import 'package:web/web.dart' as web;

const webAnswerFeedbackId = 'coolschool-answer-feedback';

/// Browser-owned banner so Flutter web testers see Richtig/Schade in the DOM
/// and on screen even if the CanvasKit frame is batched with the next prompt.
void showWebAnswerFeedback({required bool correct, required String label}) {
  final existing = web.document.getElementById(webAnswerFeedbackId);
  final el = (existing ?? web.HTMLDivElement()) as web.HTMLElement;
  el.id = webAnswerFeedbackId;
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', 'assertive');
  el.setAttribute('data-correct', correct ? 'true' : 'false');
  el.setAttribute('data-testid', 'answer-feedback');
  el.textContent = label;
  if (existing == null) {
    web.document.body?.append(el);
  }
}

void hideWebAnswerFeedback() {
  web.document.getElementById(webAnswerFeedbackId)?.remove();
}
