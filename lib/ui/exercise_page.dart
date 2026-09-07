import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../audio/speech_service.dart';
import '../content/models.dart';
import '../game/scoring.dart';
import '../l10n/strings.dart';
import 'reward_page.dart';
import 'theme.dart';
import 'web_feedback_overlay.dart';
import 'widgets/kid_chrome.dart';
import 'widgets/mute_button.dart';

/// Input / feedback lock for one exercise.
///
/// Kept as an explicit phase so the hold frame cannot be batched with the
/// next-question [setState], and so widget tests can pump pending timers
/// while [FeedbackPhase.locked] is still on screen.
enum FeedbackPhase {
  /// Waiting for a tap.
  answering,

  /// Answer chosen: input locked, banner + pill colors must paint and stay.
  locked,
}

class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.pack,
    required this.levelIndex,
  });

  /// Real wall-clock time the Richtig/Schade banner stays visible.
  static const answerFeedbackHold = Duration(milliseconds: 1600);

  final ContentPack pack;
  final int levelIndex;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage>
    with SingleTickerProviderStateMixin {
  late final RunRecorder _run;
  late final AnimationController _shake;
  SpeechService? _speech;
  Timer? _holdTimer;
  int _index = 0;
  int? _picked;

  /// Snapshot of correctness so the banner never reads the next exercise.
  bool? _feedbackCorrect;
  FeedbackPhase _phase = FeedbackPhase.answering;

  /// True after Flutter has painted at least one [FeedbackPhase.locked] frame.
  bool _feedbackPainted = false;
  bool _holdElapsed = false;

  Level get _level => widget.pack.levels[widget.levelIndex];
  Exercise get _exercise => _level.exercises[_index];
  bool get _locked => _phase == FeedbackPhase.locked;

  @override
  void initState() {
    super.initState();
    _run = RunRecorder(total: _level.exercises.length);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speech = AppScope.of(context).speech;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    hideWebAnswerFeedback();
    _shake.dispose();
    _speech?.stop();
    super.dispose();
  }

  Future<void> _speakCurrent() async {
    if (!mounted) return;
    final scope = AppScope.of(context);
    await scope.speech.speak(
      _exercise.promptTts,
      locale: scope.settings.locale,
      muted: scope.settings.muted,
    );
  }

  /// Synchronous on purpose: an `async` [onPressed] that later [setState]s the
  /// next prompt can keep the pointer handler alive on Flutter web and skip
  /// painting the hold frame entirely.
  void _pick(int choice) {
    if (_phase != FeedbackPhase.answering) return;
    final correct = _exercise.isCorrect(choice);
    final i18n = I18n(AppScope.of(context).settings.locale);
    final label = correct ? i18n.correct : i18n.wrong;
    setState(() {
      _phase = FeedbackPhase.locked;
      _picked = choice;
      _feedbackCorrect = correct;
      _feedbackPainted = false;
      _holdElapsed = false;
    });
    // DOM write is synchronous so Chrome sees the banner in this tap turn.
    showWebAnswerFeedback(correct: correct, label: label);
    _run.mark(correct);

    // Paint the locked frame first, then start wall-clock hold + SFX.
    // Do not await I/O here — that is what raced the hold on web.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != FeedbackPhase.locked) return;
      _feedbackPainted = true;
      unawaited(_playAnswerCues(correct));
      _holdTimer?.cancel();
      _holdTimer = Timer(ExercisePage.answerFeedbackHold, () {
        _holdElapsed = true;
        _advanceAfterHold();
      });
    });
  }

  Future<void> _playAnswerCues(bool correct) async {
    if (!mounted) return;
    final scope = AppScope.of(context);
    try {
      await scope.speech.stop();
    } catch (_) {}
    if (!mounted) return;
    if (correct) {
      unawaited(scope.sfx.correct());
    } else {
      unawaited(scope.sfx.wrong());
      unawaited(_shake.forward(from: 0));
    }
  }

  void _advanceAfterHold() {
    if (!mounted || _phase != FeedbackPhase.locked) return;
    // Never clear feedback in the same frame that first showed it.
    if (!_feedbackPainted || !_holdElapsed) return;
    hideWebAnswerFeedback();

    if (_run.isComplete) {
      unawaited(_finishRun());
      return;
    }

    _shake.stop();
    _shake.reset();
    unawaited(AppScope.of(context).sfx.next());
    setState(() {
      _index += 1;
      _picked = null;
      _feedbackCorrect = null;
      _phase = FeedbackPhase.answering;
      _feedbackPainted = false;
      _holdElapsed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_speakCurrent());
    });
  }

  Future<void> _finishRun() async {
    final scope = AppScope.of(context);
    final score = _run.score;
    await scope.progress.recordBest(_level.id, score.stars);
    if (score.passed) {
      unawaited(scope.sfx.levelUp());
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RewardPage(
          pack: widget.pack,
          levelIndex: widget.levelIndex,
          score: score,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final i18n = I18n(scope.settings.locale);
    final progress = (_index + 1) / _level.exercises.length;
    final showingFeedback = _phase == FeedbackPhase.locked && _picked != null;
    return ListenableBuilder(
      listenable: scope.settings,
      builder: (context, _) {
        return SkyBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: IconButton(
                tooltip: i18n.back,
                icon: const Icon(Icons.arrow_back_rounded, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                _level.title,
                style: CoolTheme.kid(size: 22, weight: FontWeight.w700),
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: MuteButton(),
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            i18n.progress(_index + 1, _level.exercises.length),
                            style: CoolTheme.kid(size: 16, color: CoolColors.inkSoft),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.white,
                              color: CoolColors.leaf,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Widget-tree banner for tests and native. Flutter web
                          // also paints a real DOM banner (see web_feedback_overlay)
                          // so CanvasKit cannot skip the hold text.
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 120),
                            switchInCurve: Curves.easeOut,
                            child: showingFeedback && !kIsWeb
                                ? _FeedbackBanner(
                                    key: const ValueKey<String>('answer-feedback-banner'),
                                    correct: _feedbackCorrect ?? false,
                                    label: (_feedbackCorrect ?? false)
                                        ? i18n.correct
                                        : i18n.wrong,
                                  )
                                : const SizedBox(
                                    key: ValueKey<String>('answer-feedback-empty'),
                                    height: 0,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        children: [
                          AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) {
                              final t = _shake.value;
                              final dx = (t == 0 || t == 1)
                                  ? 0.0
                                  : 10 * (1 - t) * (t < 0.5 ? 1 : -1);
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: KidCard(
                              child: Column(
                                children: [
                                  if (_exercise.items.isNotEmpty) ...[
                                    _ItemSpread(items: _exercise.items),
                                    const SizedBox(height: 12),
                                  ],
                                  if (_exercise.visual != null &&
                                      _exercise.visual!.trim().isNotEmpty) ...[
                                    Text(
                                      _exercise.visual!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 64),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    _exercise.prompt,
                                    textAlign: TextAlign.center,
                                    style: CoolTheme.kid(
                                      size: _exercise.kind == ExerciseKind.math ? 44 : 32,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  KidPillButton(
                                    label: i18n.speak,
                                    icon: Icons.record_voice_over_rounded,
                                    color: CoolColors.sky,
                                    onPressed: _locked ? null : _speakCurrent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_exercise.usesPictureChoices)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (var i = 0; i < _exercise.choices.length; i++)
                                  SizedBox(
                                    width: 148,
                                    child: _ChoiceButton(
                                      label: _exercise.choices[i],
                                      picture: true,
                                      state: _choiceState(i),
                                      locked: _locked,
                                      onPressed: () => _pick(i),
                                    ),
                                  ),
                              ],
                            )
                          else
                            for (var i = 0; i < _exercise.choices.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ChoiceButton(
                                  label: _exercise.choices[i],
                                  state: _choiceState(i),
                                  locked: _locked,
                                  onPressed: () => _pick(i),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _ChoiceState _choiceState(int index) {
    if (_phase != FeedbackPhase.locked || _picked == null) {
      return _ChoiceState.idle;
    }
    if (index == _exercise.correctIndex) return _ChoiceState.right;
    if (index == _picked) return _ChoiceState.wrong;
    return _ChoiceState.idle;
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    super.key,
    required this.correct,
    required this.label,
  });

  final bool correct;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = correct ? CoolColors.leaf : CoolColors.rose;
    final edge = correct ? CoolColors.leafDeep : CoolColors.roseDeep;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: edge, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 44,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  key: const ValueKey<String>('answer-feedback'),
                  textAlign: TextAlign.center,
                  style: CoolTheme.kid(
                    size: 36,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemSpread extends StatelessWidget {
  const _ItemSpread({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < items.length; i++)
          Text(
            items[i],
            key: ValueKey<String>('count-item-$i'),
            style: const TextStyle(fontSize: 48),
          ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.state,
    required this.locked,
    required this.onPressed,
    this.picture = false,
  });

  final String label;
  final _ChoiceState state;
  final bool locked;
  final VoidCallback onPressed;
  final bool picture;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ChoiceState.right => CoolColors.leaf,
      _ChoiceState.wrong => CoolColors.rose,
      _ChoiceState.idle => CoolColors.card,
    };
    final fg = state == _ChoiceState.idle ? CoolColors.ink : Colors.white;
    final border = switch (state) {
      _ChoiceState.right => CoolColors.leafDeep,
      _ChoiceState.wrong => CoolColors.roseDeep,
      _ChoiceState.idle => null,
    };
    final icon = switch (state) {
      _ChoiceState.right => Icons.check_rounded,
      _ChoiceState.wrong => Icons.close_rounded,
      _ChoiceState.idle => null,
    };
    return KidPillButton(
      key: ValueKey<String>('choice-$label'),
      label: label,
      color: color,
      foreground: fg,
      icon: picture ? null : icon,
      labelSize: picture ? 40 : 22,
      borderColor: border,
      borderWidth: state == _ChoiceState.idle ? 0 : 4,
      onPressed: locked && state == _ChoiceState.idle ? null : onPressed,
    );
  }
}

enum _ChoiceState { idle, right, wrong }
