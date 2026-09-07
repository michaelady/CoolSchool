import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../content/models.dart';
import '../game/scoring.dart';
import '../l10n/strings.dart';
import 'exercise_page.dart';
import 'navigation.dart';
import 'theme.dart';
import 'widgets/kid_chrome.dart';
import 'widgets/star_row.dart';
import 'widgets/sun_mascot.dart';

class RewardPage extends StatelessWidget {
  const RewardPage({
    super.key,
    required this.pack,
    required this.levelIndex,
    required this.score,
  });

  final ContentPack pack;
  final int levelIndex;
  final RunScore score;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final i18n = I18n(scope.settings.locale);
    final hasNext = levelIndex + 1 < pack.levels.length &&
        LevelUnlock.isUnlocked(
          levelIndex: levelIndex + 1,
          levels: pack.levels,
          starsByLevelId: {
            ...scope.progress.starsByLevelId,
            pack.levels[levelIndex].id: score.stars,
          },
        );
    return SkyBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: i18n.back,
            icon: const Icon(Icons.arrow_back_rounded, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(i18n.rewardTitle, style: CoolTheme.kid(size: 22, weight: FontWeight.w700)),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                const SunMascot(size: 128),
                const SizedBox(height: 8),
                Text(
                  i18n.rewardTitle,
                  textAlign: TextAlign.center,
                  style: CoolTheme.kid(size: 32, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.starsLabel(score.stars),
                  textAlign: TextAlign.center,
                  style: CoolTheme.kid(size: 20, color: CoolColors.inkSoft),
                ),
                const SizedBox(height: 16),
                Center(child: StarRow(filled: score.stars, size: 48)),
                const SizedBox(height: 28),
                KidPillButton(
                  label: i18n.again,
                  icon: Icons.replay_rounded,
                  color: CoolColors.sky,
                  onPressed: () {
                    unawaited(scope.sfx.transition());
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => ExercisePage(
                          pack: pack,
                          levelIndex: levelIndex,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (hasNext)
                  KidPillButton(
                    label: i18n.nextLevel,
                    icon: Icons.arrow_forward_rounded,
                    color: CoolColors.leaf,
                    onPressed: () {
                      unawaited(scope.sfx.transition());
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => ExercisePage(
                            pack: pack,
                            levelIndex: levelIndex + 1,
                          ),
                        ),
                      );
                    },
                  ),
                if (hasNext) const SizedBox(height: 12),
                KidPillButton(
                  key: const ValueKey<String>('reward-home'),
                  label: i18n.home,
                  icon: Icons.home_rounded,
                  color: CoolColors.coral,
                  onPressed: () => goHome(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
