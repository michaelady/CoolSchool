import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../content/models.dart';
import '../game/scoring.dart';
import '../l10n/strings.dart';
import 'exercise_page.dart';
import 'navigation.dart';
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pack.levels.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        return _LevelTile(
                          pack: pack,
                          index: index,
                          i18n: i18n,
                        );
                      },
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({
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
      completedLevelIds: scope.progress.completedLevelIds,
    );
    final stars = scope.progress.starsFor(level.id);
    return KidCard(
      key: ValueKey<String>('level-${index + 1}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        pushKidPage(context, ExercisePage(pack: pack, levelIndex: index));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}',
            style: CoolTheme.kid(size: 26, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (unlocked)
            StarRow(filled: stars, size: 12)
          else
            const Icon(Icons.lock_rounded, size: 18, color: CoolColors.inkSoft),
        ],
      ),
    );
  }
}
