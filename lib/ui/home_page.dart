import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../content/models.dart';
import '../l10n/app_locales.dart';
import '../l10n/strings.dart';
import 'navigation.dart';
import 'theme.dart';
import 'topic_page.dart';
import 'widgets/kid_chrome.dart';
import 'widgets/mute_button.dart';
import 'widgets/sun_mascot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ContentPack> _packs = const [];
  Object? _error;
  bool _loading = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    try {
      final packs = await scope.packs.loadAll(scope.settings.locale);
      if (!mounted) return;
      setState(() {
        _packs = packs;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _switchLocale(String locale) async {
    final scope = AppScope.of(context);
    scope.settings.setLocale(locale);
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final i18n = I18n(scope.settings.locale);
    return SkyBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  // Equal-width chips in their own row so RO cannot wrap
                  // under the mute button or get clipped by a tight Wrap.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _LanguageChipBar(
                          selected: i18n.lang,
                          onSelected: _switchLocale,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const MuteButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SunMascot(size: 120),
                  const SizedBox(height: 8),
                  Text(
                    'CoolSchool',
                    textAlign: TextAlign.center,
                    style: CoolTheme.kid(size: 42, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.tagline,
                    textAlign: TextAlign.center,
                    style: CoolTheme.kid(size: 18, color: CoolColors.inkSoft),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i18n.ageNote,
                    textAlign: TextAlign.center,
                    style: CoolTheme.kid(size: 14, color: CoolColors.inkSoft, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    KidCard(
                      child: Text(
                        '$_error',
                        style: CoolTheme.kid(size: 16, color: CoolColors.rose),
                      ),
                    )
                  else
                    for (var i = 0; i < _packs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _TopicCard(
                        emoji: _packs[i].emoji,
                        title: _packs[i].title,
                        subtitle: _packs[i].subtitle,
                        badge: _packs[i].lp21.badge,
                        color: parseHexColor(_packs[i].color),
                        onTap: () {
                          pushKidPage(context, TopicPage(pack: _packs[i]));
                        },
                      ),
                    ],
                  const SizedBox(height: 28),
                  Text(
                    i18n.footer,
                    textAlign: TextAlign.center,
                    style: CoolTheme.kid(size: 13, color: CoolColors.inkSoft, weight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageChipBar extends StatelessWidget {
  const _LanguageChipBar({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < AppLocales.codes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _LocaleChip(
              key: ValueKey<String>('locale-chip-${AppLocales.codes[i]}'),
              label: AppLocales.chips[AppLocales.codes[i]]!,
              selected: selected == AppLocales.codes[i],
              onTap: () => onSelected(AppLocales.codes[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocaleChip extends StatelessWidget {
  const _LocaleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? CoolColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: CoolTheme.kid(
                  size: 16,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : CoolColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KidCard(
      color: color.withValues(alpha: 0.92),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CoolTheme.kid(size: 26, weight: FontWeight.w700)),
                Text(subtitle, style: CoolTheme.kid(size: 16, color: CoolColors.inkSoft)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge, style: CoolTheme.kid(size: 12, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 32,
            color: CoolColors.ink,
          ),
        ],
      ),
    );
  }
}
