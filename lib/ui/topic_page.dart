import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../content/models.dart';
import '../game/scoring.dart';
import '../l10n/strings.dart';
import 'exercise_page.dart';
import 'theme.dart';
import 'widgets/kid_chrome.dart';
import 'widgets/mute_button.dart';
import 'widgets/star_row.dart';

class TopicPage extends StatelessWidget {
  const TopicPage({super.key, required this.pack});

  final ContentPack pack;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final i18n = I18n(scope.settings.locale);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.progress, scope.settings]),
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
              title: Text(pack.title, style: CoolTheme.kid(size: 24, weight: FontWeight.w700)),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: MuteButton(),
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    KidCard(
                      color: parseHexColor(pack.color).withValues(alpha: 0.9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pack.emoji}  ${pack.subtitle}', style: CoolTheme.kid(size: 22)),
                          const SizedBox(height: 8),
                          Text(pack.lp21.badge, style: CoolTheme.kid(size: 16, weight: FontWeight.w700)),
                          Text(
                            '${pack.lp21.focusId} ${pack.lp21.focusLabel} · ${pack.lp21.cycle}',
                            style: CoolTheme.kid(size: 14, color: CoolColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(i18n.pickLevel, style: CoolTheme.kid(size: 22, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < pack.levels.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _LevelCard(
                          pack: pack,
                          index: i,
                          i18n: i18n,
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
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.pack,
    required this.index,
    required this.i18n,
  });

  final ContentPack pack;
  final int index;
  final I18n i18n;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final level = pack.levels[index];
    final unlocked = LevelUnlock.isUnlocked(
      levelIndex: index,
      levels: pack.levels,
      starsByLevelId: scope.progress.starsByLevelId,
    );
    final stars = scope.progress.starsFor(level.id);
    return KidCard(
      color: unlocked ? CoolColors.card : const Color(0xFFE8E4F0),
      onTap: () {
        if (!unlocked) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: CoolColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Text(i18n.lockedHint, style: CoolTheme.kid(size: 16, color: Colors.white)),
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExercisePage(pack: pack, levelIndex: index),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: unlocked ? CoolColors.sky : Colors.white,
            child: Text(
              '${index + 1}',
              style: CoolTheme.kid(size: 24, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.title, style: CoolTheme.kid(size: 22, weight: FontWeight.w700)),
                Text(level.subtitle, style: CoolTheme.kid(size: 15, color: CoolColors.inkSoft)),
                const SizedBox(height: 4),
                Text(level.lp21Tag, style: CoolTheme.kid(size: 12, color: CoolColors.inkSoft)),
                const SizedBox(height: 6),
                StarRow(filled: stars, size: 22),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
            size: 36,
            color: CoolColors.ink,
          ),
        ],
      ),
    );
  }
}
