import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  final Storage storage;
  const HomeScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.fromMode(storage.themeMode);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              _buildLogo(t),
              const Spacer(flex: 3),
              _ModeCard(
                theme: t,
                icon: Icons.grid_view_rounded,
                title: 'Classic',
                subtitle: 'Place blocks, clear lines, beat your best',
                primary: true,
                onTap: () => _openClassic(context),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                theme: t,
                icon: Icons.bolt,
                title: 'Challenge',
                subtitle: 'Timed levels and daily puzzles',
                primary: false,
                comingSoon: true,
                onTap: () => _showComingSoon(context, t),
              ),
              const Spacer(flex: 2),
              if (storage.hiScore > 0)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events,
                          size: 16, color: t.textSecondary),
                      const SizedBox(width: 6),
                      Text('Best: ${storage.hiScore}',
                          style: TextStyle(
                              color: t.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(AppTheme t) {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: t.accent.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Block Arena',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PUZZLE',
          style: TextStyle(
            color: t.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  void _openClassic(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(storage: storage),
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppTheme t) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: t.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(Icons.hourglass_empty, color: t.accent, size: 18),
              const SizedBox(width: 10),
              Text('Challenge mode is coming soon',
                  style: TextStyle(color: t.textPrimary)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _ModeCard extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final bool comingSoon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final bg = primary ? t.accent : t.surface;
    final fg = primary ? Colors.white : t.textPrimary;
    final fgSub = primary
        ? Colors.white.withValues(alpha: 0.85)
        : t.textSecondary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: primary
                ? null
                : Border.all(
                    color: t.textSecondary.withValues(alpha: 0.15)),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: t.accent.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.18)
                      : t.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    color: primary ? Colors.white : t.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: fg,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        if (comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('SOON',
                                style: TextStyle(
                                    color: t.accent,
                                    fontSize: 9,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            color: fgSub,
                            fontSize: 12.5,
                            height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: primary
                      ? Colors.white.withValues(alpha: 0.9)
                      : t.textSecondary,
                  size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
