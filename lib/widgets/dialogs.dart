import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

const _kDialogRadius = 20.0;
const _kButtonRadius = 12.0;

BoxDecoration _dialogDecoration(AppTheme t) => BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(_kDialogRadius),
      border: Border.all(
        color: t.textSecondary.withValues(alpha: 0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
    );

Widget _dialogShell(AppTheme t, Widget child, {EdgeInsets? padding}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: Container(
      decoration: _dialogDecoration(t),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    ),
  );
}

Widget _primaryButton({
  required AppTheme t,
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kButtonRadius)),
        elevation: 0,
      ),
      onPressed: onPressed,
    ),
  );
}

Widget _secondaryButton({
  required AppTheme t,
  IconData? icon,
  required String label,
  required VoidCallback onPressed,
}) {
  final child = Text(label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
  return SizedBox(
    width: double.infinity,
    child: icon == null
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: t.textPrimary,
              side: BorderSide(
                  color: t.textSecondary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kButtonRadius)),
            ),
            onPressed: onPressed,
            child: child,
          )
        : OutlinedButton.icon(
            icon: Icon(icon, size: 20, color: t.textPrimary),
            label: child,
            style: OutlinedButton.styleFrom(
              foregroundColor: t.textPrimary,
              side: BorderSide(
                  color: t.textSecondary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kButtonRadius)),
            ),
            onPressed: onPressed,
          ),
  );
}

Widget _dialogHeader(AppTheme t, IconData icon, String title,
    {String? subtitle}) {
  return Column(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: t.accent, size: 28),
      ),
      const SizedBox(height: 14),
      Text(title,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: t.textPrimary)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.textSecondary)),
      ],
    ],
  );
}

class GameOverDialog extends StatelessWidget {
  final int score, hiScore;
  final bool adUsed;
  final AppTheme theme;
  final VoidCallback onRewardedAd, onRestart;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.hiScore,
    required this.adUsed,
    required this.theme,
    required this.onRewardedAd,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = score > 0 && score >= hiScore;
    return _dialogShell(
      theme,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(
            theme,
            isNewBest ? Icons.emoji_events : Icons.flag,
            'Game Over',
            subtitle: 'No room to place blocks',
          ),
          const SizedBox(height: 20),
          if (isNewBest)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('NEW BEST',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text('$score',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                  height: 1,
                  shadows: [
                    Shadow(
                        color: theme.accent.withValues(alpha: 0.35),
                        blurRadius: 18),
                  ])),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events,
                  size: 14, color: theme.textSecondary),
              const SizedBox(width: 4),
              Text('Best: $hiScore',
                  style: TextStyle(
                      fontSize: 13, color: theme.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          if (!adUsed) ...[
            _primaryButton(
              t: theme,
              icon: Icons.play_circle_outline,
              label: 'Watch ad to continue',
              onPressed: onRewardedAd,
            ),
            const SizedBox(height: 10),
          ],
          _secondaryButton(
            t: theme,
            icon: Icons.refresh,
            label: 'Play again',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class RewardedAdDialog extends StatefulWidget {
  final VoidCallback onComplete;
  final AppTheme theme;

  const RewardedAdDialog({
    super.key,
    required this.onComplete,
    required this.theme,
  });

  @override
  State<RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<RewardedAdDialog> {
  static const _total = 5;
  int _seconds = _total;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (_seconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _seconds--);
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final progress = (_total - _seconds) / _total;
    return _dialogShell(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('AD',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: t.textSecondary,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 14),
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: t.textSecondary.withValues(alpha: 0.12)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 52, color: t.textSecondary),
                  const SizedBox(height: 10),
                  Text('AdMob ad will appear here',
                      style:
                          TextStyle(fontSize: 13, color: t.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor:
                        t.textSecondary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(t.accent),
                  ),
                ),
                Text('$_seconds',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: t.accent)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Continuing in $_seconds s',
              style: TextStyle(fontSize: 13, color: t.textSecondary)),
        ],
      ),
    );
  }
}

class PauseDialog extends StatelessWidget {
  final GameState game;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenSettings;
  final VoidCallback onHome;

  const PauseDialog({
    super.key,
    required this.game,
    required this.onResume,
    required this.onRestart,
    required this.onOpenStats,
    required this.onOpenSettings,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final t = game.theme;
    return _dialogShell(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(t, Icons.pause_circle_outline, 'Paused'),
          const SizedBox(height: 22),
          _primaryButton(
            t: t,
            icon: Icons.play_arrow,
            label: 'Resume',
            onPressed: onResume,
          ),
          const SizedBox(height: 10),
          _menuTile(t, Icons.bar_chart, 'Statistics', onOpenStats),
          const SizedBox(height: 8),
          _menuTile(t, Icons.settings, 'Settings', onOpenSettings),
          const SizedBox(height: 8),
          _menuTile(t, Icons.refresh, 'Restart', onRestart),
          const SizedBox(height: 8),
          _menuTile(t, Icons.home, 'Home', onHome),
        ],
      ),
    );
  }

  Widget _menuTile(
      AppTheme t, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kButtonRadius),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: t.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(_kButtonRadius),
            border: Border.all(
                color: t.textSecondary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: t.textPrimary),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.chevron_right,
                  size: 20,
                  color: t.textSecondary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsDialog extends StatelessWidget {
  final GameState game;
  const StatsDialog({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final t = game.theme;
    final unlocked =
        kAchievements.where((a) => game.achievements.contains(a.id)).length;
    return _dialogShell(
      t,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(t, Icons.bar_chart, 'Statistics'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _statTile(t, Icons.emoji_events, 'Best',
                      '${game.hiScore}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile(t, Icons.videogame_asset, 'Games',
                      '${game.gamesPlayed}')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _statTile(t, Icons.cleaning_services, 'Cleared',
                      '${game.totalCleared}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile(t, Icons.local_fire_department,
                      'Best combo', 'x${game.bestCombo}')),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('Achievements',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary)),
              const Spacer(),
              Text('$unlocked / ${kAchievements.length}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.accent)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kAchievements.map((a) {
              final isUnlocked = game.achievements.contains(a.id);
              return Tooltip(
                message: '${a.title}\n${a.description}',
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? t.accent.withValues(alpha: 0.18)
                        : t.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked
                          ? t.accent
                          : t.textSecondary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    a.icon,
                    color: isUnlocked
                        ? t.accent
                        : t.textSecondary.withValues(alpha: 0.35),
                    size: 22,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _secondaryButton(
            t: t,
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _statTile(AppTheme t, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: t.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: t.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: t.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final GameState game;
  final void Function(AppThemeMode) onThemeChange;
  const SettingsDialog(
      {super.key, required this.game, required this.onThemeChange});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _sound;
  late bool _haptic;
  late AppThemeMode _theme;

  @override
  void initState() {
    super.initState();
    _sound = widget.game.storage.soundOn;
    _haptic = widget.game.storage.hapticOn;
    _theme = widget.game.theme.mode;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.game.theme;
    return _dialogShell(
      t,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(t, Icons.tune, 'Settings'),
          const SizedBox(height: 22),
          _sectionLabel(t, 'Audio & Feedback'),
          const SizedBox(height: 8),
          _toggleTile(
            t,
            Icons.volume_up,
            'Sound',
            _sound,
            (v) {
              setState(() => _sound = v);
              widget.game.storage.setSoundOn(v);
            },
          ),
          const SizedBox(height: 8),
          _toggleTile(
            t,
            Icons.vibration,
            'Vibration',
            _haptic,
            (v) {
              setState(() => _haptic = v);
              widget.game.storage.setHapticOn(v);
            },
          ),
          const SizedBox(height: 18),
          _sectionLabel(t, 'Appearance'),
          const SizedBox(height: 10),
          Row(
            children: AppTheme.all.map((th) {
              final selected = th.mode == _theme;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _theme = th.mode);
                      widget.onThemeChange(th.mode);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: th.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? th.accent
                              : t.textSecondary.withValues(alpha: 0.15),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: th.pieceColors.take(4).map((c) {
                              return Container(
                                width: 11,
                                height: 11,
                                margin: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (selected) ...[
                                Icon(Icons.check_circle,
                                    color: th.accent, size: 12),
                                const SizedBox(width: 3),
                              ],
                              Text(th.displayName,
                                  style: TextStyle(
                                      color: th.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          _secondaryButton(
            t: t,
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppTheme t, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: t.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }

  Widget _toggleTile(AppTheme t, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: t.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(_kButtonRadius),
        border: Border.all(
            color: t.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: t.textPrimary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Switch(
            value: value,
            activeThumbColor: t.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
