import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../audio/speech_service.dart';
import '../content/models.dart';
import '../game/scoring.dart';
import '../l10n/strings.dart';
import 'reward_page.dart';
import 'theme.dart';
import 'widgets/kid_chrome.dart';
import 'widgets/mute_button.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.pack,
    required this.levelIndex,
  });

  /// How long the chosen answer stays highlighted before the next prompt.
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
  int _index = 0;
  int? _picked;
  bool _locked = false;

  Level get _level => widget.pack.levels[widget.levelIndex];
  Exercise get _exercise => _level.exercises[_index];

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

  Future<void> _pick(int choice) async {
    if (_locked) return;
    final scope = AppScope.of(context);
    final correct = _exercise.isCorrect(choice);
    setState(() {
      _picked = choice;
      _locked = true;
    });
    await scope.speech.stop();
    if (!mounted) return;
    // Fire SFX without awaiting playback so the green/red hold is reliable.
    if (correct) {
      unawaited(scope.sfx.correct());
    } else {
      unawaited(scope.sfx.wrong());
      unawaited(_shake.forward(from: 0));
    }
    _run.mark(correct);
    await Future<void>.delayed(ExercisePage.answerFeedbackHold);
    if (!mounted) return;
    if (_run.isComplete) {
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
      return;
    }
    setState(() {
      _index += 1;
      _picked = null;
      _locked = false;
    });
    await _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final i18n = I18n(scope.settings.locale);
    final progress = (_index + 1) / _level.exercises.length;
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) {
                        final t = _shake.value;
                        final dx = (t == 0 || t == 1)
                            ? 0.0
                            : 10 * (1 - t) * (t < 0.5 ? 1 : -1);
                        return Transform.translate(offset: Offset(dx, 0), child: child);
                      },
                      child: KidCard(
                        child: Column(
                          children: [
                            Text(
                              _exercise.prompt,
                              textAlign: TextAlign.center,
                              style: CoolTheme.kid(size: 44, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            KidPillButton(
                              label: i18n.speak,
                              icon: Icons.record_voice_over_rounded,
                              color: CoolColors.sky,
                              onPressed: _speakCurrent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_picked != null) ...[
                      const SizedBox(height: 16),
                      _FeedbackBanner(
                        correct: _exercise.isCorrect(_picked!),
                        label: _exercise.isCorrect(_picked!) ? i18n.correct : i18n.wrong,
                      ),
                    ],
                    const SizedBox(height: 20),
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
            ),
          ),
        );
      },
    );
  }

  _ChoiceState _choiceState(int index) {
    if (_picked == null) return _ChoiceState.idle;
    if (index == _exercise.correctIndex) return _ChoiceState.right;
    if (index == _picked) return _ChoiceState.wrong;
    return _ChoiceState.idle;
  }
}

enum _ChoiceState { idle, right, wrong }

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.correct, required this.label});

  final bool correct;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = correct ? CoolColors.leaf : CoolColors.rose;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: correct ? CoolColors.leafDeep : CoolColors.roseDeep,
            width: 4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  key: const ValueKey<String>('answer-feedback'),
                  textAlign: TextAlign.center,
                  style: CoolTheme.kid(size: 28, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.state,
    required this.locked,
    required this.onPressed,
  });

  final String label;
  final _ChoiceState state;
  final bool locked;
  final VoidCallback onPressed;

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
      icon: icon,
      borderColor: border,
      borderWidth: state == _ChoiceState.idle ? 0 : 4,
      onPressed: locked && state == _ChoiceState.idle ? null : onPressed,
    );
  }
}
