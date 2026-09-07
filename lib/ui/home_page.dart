import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../content/models.dart';
import '../l10n/strings.dart';
import 'theme.dart';
import 'topic_page.dart';
import 'widgets/kid_chrome.dart';
import 'widgets/sun_mascot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialPack});

  final ContentPack? initialPack;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ContentPack? _pack;
  Object? _error;
  bool _loading = true;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pack = widget.initialPack;
    _loading = widget.initialPack == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || widget.initialPack != null) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    try {
      final pack = await scope.packs.loadAddition(scope.settings.locale);
      if (!mounted) return;
      setState(() {
        _pack = pack;
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
                  Row(
                    children: [
                      _LocaleChip(
                        label: i18n.deChip,
                        selected: !i18n.isFr,
                        onTap: () => _switchLocale('de'),
                      ),
                      const SizedBox(width: 8),
                      _LocaleChip(
                        label: i18n.frChip,
                        selected: i18n.isFr,
                        onTap: () => _switchLocale('fr'),
                      ),
                      const Spacer(),
                      RoundIconButton(
                        icon: scope.settings.muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        tooltip: scope.settings.muted ? i18n.unmute : i18n.mute,
                        selected: scope.settings.muted,
                        onPressed: () => setState(scope.settings.toggleMute),
                      ),
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
                  else ...[
                    _TopicCard(
                      emoji: _pack!.emoji,
                      title: _pack!.title,
                      subtitle: _pack!.subtitle,
                      badge: _pack!.lp21.badge,
                      color: parseHexColor(_pack!.color),
                      locked: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TopicPage(pack: _pack!),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _TopicCard(
                      emoji: '➖',
                      title: i18n.subtraction,
                      subtitle: i18n.additionSoonNote,
                      badge: 'MA.1 ${i18n.isFr ? 'Nombre et variable' : 'Zahl und Variable'}',
                      color: CoolColors.grape,
                      locked: true,
                      onTap: () => _soon(context, i18n),
                    ),
                    const SizedBox(height: 16),
                    _TopicCard(
                      emoji: '🔷',
                      title: i18n.shapes,
                      subtitle: i18n.additionSoonNote,
                      badge: 'MA.2 ${i18n.isFr ? 'Forme et espace' : 'Form und Raum'}',
                      color: CoolColors.leaf,
                      locked: true,
                      onTap: () => _soon(context, i18n),
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

  void _soon(BuildContext context, I18n i18n) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CoolColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(i18n.comingSoonHint, style: CoolTheme.kid(size: 16, color: Colors.white)),
      ),
    );
  }
}

class _LocaleChip extends StatelessWidget {
  const _LocaleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CoolColors.ink : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: CoolTheme.kid(
              size: 16,
              weight: FontWeight.w700,
              color: selected ? Colors.white : CoolColors.ink,
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
    required this.locked,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KidCard(
      color: color.withValues(alpha: locked ? 0.55 : 0.92),
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
          Icon(
            locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
            size: 32,
            color: CoolColors.ink,
          ),
        ],
      ),
    );
  }
}
